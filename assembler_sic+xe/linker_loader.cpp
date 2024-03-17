#include<bits/stdc++.h>
using namespace std;

string input="loader_inp.txt";   // output produced by assembler

// Function to format a number as a string with a specified width and padding character
string format_number(int num, int width, char pad = '0')
{
    // Create a stringstream object to build the formatted string
    stringstream temp;
    // Format the number as hexadecimal, uppercase, with the specified padding and width
    temp << std::hex << std::uppercase << std::setfill(pad) << std::setw(width) << num;
    // Return the formatted string
    return temp.str();
}

// Function to format a string with a specified width and padding character
string format_string(string name, int width, char pad = ' ')
{
    // Create a stringstream object to build the formatted string
    stringstream temp;
    // Format the string with left alignment, the specified padding, and width
    temp << std::left << std::setfill(pad) << std::setw(width) << name;
    // Return the formatted string
    return temp.str();
}

// Global variables to store program address and last address
int PROGADDR;
int LAST;

// Memory vector with a size of 2^18 initialized with "xx"
vector<string> memory((int)pow(2,18), "xx");


map<string,int> ESTAB;

void print_memory()
{
	fstream fout;
	// open memory file
	fout.open("memory.txt", ios::out);
	int i = (PROGADDR / 16) * 16;
	int n = ((LAST + 16) / 16) * 16;
	while(i < n) 
	{
		fout << format_number(i, 4) << ' ';
		for(int j = 0; j < 16; j++)
		{
			if(j%4 == 0 && j!=0) fout << ' ';
			fout << memory[i++];
		}
		fout << '\n';
	}
	// close the memory file
	fout.close();
}

void pass_1()
{
	fstream fin;
	
	// open input file
	fin.open(input, ios::in);

	if(!fin.is_open())
	{
		perror(input.c_str());
		exit(1);
	}

	int CSADDR,CSLTH;
	// Take program address as input from the user in hex
	cout << "Enter PROGADDR for the program(in hex): ";
	string progaddr,record;
	cin >> progaddr;
	PROGADDR = stoi(progaddr, nullptr, 16);

	CSADDR = PROGADDR;
	CSLTH = 0;

	while(fin.good())
	{
		// read record
		getline(fin, record);
		
		// end of input
		if(record.empty())
			break;

		if(record.front() == 'H')
		{
			// Update CSADDR
			CSADDR = CSADDR + CSLTH;

			// CSECT and CSLTH from the record
			string CSECT = record.substr(1, 6);
			CSLTH = stoi(record.substr(13, 6), nullptr, 16);

			// Enter the CSECT to ESTAB
			if(ESTAB.find(CSECT) != ESTAB.end()){
				perror("duplicate external symbol");
				exit(1);
			}
			else
			{
				ESTAB.insert({CSECT, CSADDR});
			}
		}

		else if(record.front() == 'D')
		{
			// get the symbols in the record
			vector<pair<string, int>> symbols;
			string symbol = "";
			for(int i = 1; i < record.length(); i ++ )
			{
				if((i-7)%12 == 0){
					int value=stoi(record.substr(i,6),nullptr,16);
					symbols.push_back({symbol, value});
					symbol = "";
					i+=5;
				}
				else symbol += record[i];
			}

			for(pair<string,int> symbol : symbols)
			{
				if(ESTAB.find(symbol.first) != ESTAB.end()){
					perror("duplicate external symbol");
					exit(1);
				}
				else
				{
					ESTAB.insert({symbol.first, symbol.second + CSADDR});
				}
			}
		}

	}
	LAST = CSADDR + CSLTH;
	cout<<"Symbol table after pass 1"<<endl;
	for(auto x : ESTAB)
		cout << x.first << ' ' << format_number(x.second, 4) << '\n';
}

void pass_2()
{
	fstream fin;
	
	// open input file
	fin.open(input, ios::in);

	if(!fin.is_open())
	{
		perror(input.c_str());
		exit(1);
	}


	int CSADDR = PROGADDR;
	int EXECADDR = PROGADDR;
	int CSLTH = 0;

	string record;
	while(fin.good())
	{
		getline(fin, record);

		// if end of input
		if(record.empty())
			break;

		if(record.front() == 'H')
			CSLTH = stoi(record.substr(13, 6), nullptr, 16);
		
		if(record.front() == 'T')
		{
			// move the record to its appropriate memory location byte by byte
			int STADDR = stoi(record.substr(1, 6), nullptr, 16) + CSADDR;
			int INDEX = 0;
			for(int i = 9; i < (int)record.length(); i += 2)
				memory[STADDR + INDEX++] = record.substr(i, 2); 
		}

		else if(record.front() == 'M')
		{
			string symbol = record.substr(10, 6);
			if(ESTAB.find(symbol) != ESTAB.end())
			{
				// extract address to be modified
				int address = stoi(record.substr(1, 6), nullptr, 16) + CSADDR;
				int length = stoi(record.substr(7, 2), nullptr, 16);

				char halfByte;
				if(length % 2)
					halfByte = memory[address][0];

				string val = "";
				for(int i = 0; i < (length + 1)/ 2; i++)
					val += memory[address + i];
				int value = stoi(val, nullptr, 16);
				
				// apply modification
				int modification = ESTAB[symbol];
				char sign = record[9];
				if(sign == '+')
					value += modification;
				else
					value -= modification;

				int mask = (1 << ((length + length % 2) * 4)) - 1;
				
				value = value & mask;
				
				// write back the modified value
				val = format_number(value, length + (length % 2));

				for(int i = 0; i < length; i += 2)
					memory[address + i / 2] = val.substr(i, 2);

				if(length % 2)
					memory[address][0] = halfByte;

			}
			else
			{
				for(auto x:ESTAB){
					cout<<x.first<<"."<<x.second<<" "<<x.first.length()<<endl;
				}
				cout << symbol.size() << '\n';
				perror("undefined symbol");
				exit(1);
			}
		}

		if(record.front() == 'E')
		{
			if(record != "E")
			{
				int FIRST = stoi(record.substr(1, 6), nullptr, 16);
				EXECADDR = CSADDR + FIRST;
			}
			CSADDR = CSLTH + CSADDR;
		}

	}
	
	cout << "Starting execution at: " << format_number(EXECADDR, 4) << '\n';
	print_memory();
}


int main()
{
	pass_1();
	pass_2();
	return 0;
}