%{
	/* header files */
	#include<stdio.h>
	#include<stdlib.h>
	#include<string.h>
	#include "y.tab.h"
	#define NOT_INITIALIZED -10000000

	/* declaration of useful functions and variables */
	char* install_id();
	int install_int();
	float install_real();
	int line = 0;
	extern int flag;
	#define NUM_KEYWORDS 35
	char *keywords[NUM_KEYWORDS];

	/* linked list implementation */
	typedef struct node {
		char* specifier;
		struct node* next;
	} node;
	
	struct output {
        char * id_name;
        char * data_type;
        int line_no;
	} symbol_table[100];
	int count = 0;

	node* head = NULL;
	int search_id(char* specifier) {
		// search the specifier in the linked list
		node* temp = head;
		while(temp != NULL && strcmp(specifier, temp -> specifier)) {
			temp = temp -> next; 
		}
		// 0 if not found, 1 if found
		return (temp != NULL);
	}

	int add_id(char* specifier) {
		// add a new id to the beggining of the list and return success / failure
		node* temp = (node *)malloc(sizeof(node));
		temp -> specifier = (char *)strdup(specifier);
		temp -> next = NULL;

		// if the id is already present then don't add and return failure
		if(search_id(specifier)) {
			return 0;
		}

		if(head) {
			temp -> next = head;
			head = temp;
		}
		else
			head = temp;

		// 0 for failure 1 for success
		return 1;
	}


	/* hashtable implementation */
	#define SIZE 20

	typedef struct symbol {
		char* specifier;
		float real;
		int integer;
		char type;
		int initialized;
		int declared;
		struct symbol* next;
	} symbol;

	typedef struct {
    	symbol *buckets[SIZE];
	} HashTable;

	HashTable SYMTAB;

	int hash_function(char* specifier) {
		int len = strlen(specifier);
		// simple hash function
		int hash = 0;
		int p=1;
		for(int i = 0; i < len; i++)
			hash += (p* (int) specifier[i]);
			p = (2*p)%SIZE;
			hash%=SIZE;
		return hash % SIZE;
	}

	void init() {
		// initialize all bucket to null
		for (int i = 0; i < SIZE; i++) {
        	SYMTAB.buckets[i] = NULL;
    	}
		keywords[0] = "AND";
		keywords[1] = "ARRAY";
		keywords[2] = "BEGIN";
		keywords[3] = "CASE";
		keywords[4] = "CONST";
		keywords[5] = "DIV";
		keywords[6] = "DO";
		keywords[7] = "DOWNTO";
		keywords[8] = "ELSE";
		keywords[9] = "END";
		keywords[10] = "FILE";
		keywords[11] = "FOR";
		keywords[12] = "FUNCTION";
		keywords[13] = "GOTO";
		keywords[14] = "IF";
		keywords[15] = "IN";
		keywords[16] = "LABEL";
		keywords[17] = "MOD";
		keywords[18] = "NIL";
		keywords[19] = "NOT";
		keywords[20] = "OF";
		keywords[21] = "OR";
		keywords[22] = "PACKED";
		keywords[23] = "PROCEDURE";
		keywords[24] = "PROGRAM";
		keywords[25] = "RECORD";
		keywords[26] = "REPEAT";
		keywords[27] = "SET";
		keywords[28] = "THEN";
		keywords[29] = "TO";
		keywords[30] = "TYPE";
		keywords[31] = "UNTIL";
		keywords[32] = "VAR";
		keywords[33] = "WHILE";
		keywords[34] = "WITH";
	}

	symbol* search(HashTable *hashTable, char* specifier) {
		int index = hash_function(specifier);
		symbol *current = hashTable->buckets[index];
		while (current != NULL) {
			if (strcmp(current->specifier, specifier) == 0) {
				return current;
			}
			current = current->next;
		}
		return NULL; // Key not found
	}

	symbol *createEntry(char* specifier, char type) {
		symbol* new_symbol = (symbol *)malloc(sizeof(symbol));
		if (new_symbol == NULL) {
			perror("Memory allocation failed");
			exit(EXIT_FAILURE);
		}
		new_symbol -> specifier = (char *)strdup(specifier);
		new_symbol -> real = NOT_INITIALIZED;
		new_symbol -> integer = NOT_INITIALIZED;
		new_symbol -> type = type;
		new_symbol -> initialized = 0;
		new_symbol -> declared = 0;
	}

	symbol* insert(HashTable *hashTable, char* specifier, char type) {
		int index = hash_function(specifier);

		// create the new symbol
		symbol* new_symbol = createEntry(specifier,type);

		if (hashTable->buckets[index] == NULL) {
			hashTable->buckets[index] = new_symbol;
		} else {
			symbol *current = hashTable->buckets[index];
			while (current->next != NULL) {
				current = current->next;
			}
			current->next = new_symbol;
		}
		return new_symbol;
	}

	void print_symbol_table(){
		printf("%-15s%-15s%s\n", "SYMBOL", "DATA TYPE", "LINE NUMBER");
		for(int i=0;i<count;i++){
			printf("%-15s%-15s%d\n", symbol_table[i].id_name, symbol_table[i].data_type, symbol_table[i].line_no);
		}
	}
	

	int get_int_value(char* specifier) {
		// search the symbol and get the value of the symbol
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL)
			return sym -> integer; 
	}

	float get_real_value(char* specifier) {
		// search the symbol and get the value of the symbol
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL)
			return sym -> real; 
	}

	void set_int_value(char* specifier, int val) {
		// search the symbol and set its value to val
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL) {
			sym -> initialized = 1;
			sym -> type = 'I';
			sym -> integer = val;
		}
	}

	void set_real_value(char* specifier, float val) {
		// search the symbol and set its value to val
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL) {
			sym -> initialized = 1;
			sym -> type = 'F';
			sym -> real = val;
		}
	}

	int is_declared(char* specifier) {
		// check if the specifier is declared or not
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL)
			return (sym -> declared);
	}

	int is_initialized(char* specifier) {
		// check if the specifier is initialized or not
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL) {
			return (sym -> initialized);
		}
		
	}

	int get_type(char* specifier) {
		// search the symbol and get its type
		symbol* sym = search(&SYMTAB,specifier);
		if(sym != NULL) {
			if(sym -> type == 'I')
				return 0;
			if(sym -> type == 'F')
				return 1;
			if(sym -> type == 'V')
				return 2;
		}
	}

	int set_type(int type) {
		// once the declaration list is complete then set the declaration of the variables and set their type
		node* temp = head;
		int flag = 1;
		while(temp != NULL) {
			symbol* sym = search(&SYMTAB,temp -> specifier);
			if(sym -> declared)
				flag = 0; // duplicate error
			else {
				if(type == 0)
					sym -> type = 'I';
				if(type == 1)
					sym -> type = 'F';
				sym -> declared = 1;
			}
			temp = temp -> next;
		}
		head = NULL;
		return flag;
	}

	int set_init() {
		// while reading we need to initialize all the variables in the id list
		node* temp = head;
		int flag = 1;
		while(temp != NULL) {
			symbol* sym = search(&SYMTAB,temp -> specifier);
			if(sym -> declared == 0) // missing declaration
				flag = 0;
			else 
				sym -> initialized = 1;
			temp = temp -> next;
		}
		head = NULL;
		return flag;
	}

	void clear_list() {
		head = NULL;
	}

%}

delim		[ \t\n]
letter		[A-Za-z]
digit		[0-9]
id		{letter}({letter}|{digit})*
int		{digit}+
real  		{digit}+(\.{digit}+)?(E[+-]?{digit}+)?

%%
[\n]		{ line++;								}
[ \t\r]		{									}
PROGRAM		{ 
	symbol_table[count].id_name=strdup("PROGRAM");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _PROGRAM ;								
}
VAR		{
	symbol_table[count].id_name=strdup("VAR");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _VAR ;	
}
BEGIN		{ 
	symbol_table[count].id_name=strdup("BEGIN");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _BEGIN ;	
}
END		{ 
	symbol_table[count].id_name=strdup("END");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _END ;	
}
END\.		{ 
	symbol_table[count].id_name=strdup("END_DOT");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _END_DOT ;	
}
INTEGER		{ 
	symbol_table[count].id_name=strdup("INTEGER");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _INTEGER ;	
}
REAL		{ 
	symbol_table[count].id_name=strdup("REAL");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _REAL ;	
}
FOR		{ 
	symbol_table[count].id_name=strdup("FOR");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _FOR ;	
}
READ		{ 
	symbol_table[count].id_name=strdup("READ");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _READ ;	
}
WRITE		{ 
	symbol_table[count].id_name=strdup("WRITE");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _WRITE ;	
}
TO		{ 
	symbol_table[count].id_name=strdup("TO");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _TO ;	
}
DO		{ 
	symbol_table[count].id_name=strdup("DO");
	symbol_table[count].data_type=strdup("Keyword");
	symbol_table[count].line_no=line+1;
	count++;
	return _DO ;	
}
\;		{ return _SEMICOLON;								}
\:		{ return _COLON;								}
\,		{ return _COMMA;								}
\:\=		{ return _ASSIGN;								}
\+		{ return _ADD;									}
\-		{ return _SUB;									}
\*		{ return _MUL;									}
DIV		{ 
		symbol_table[count].id_name=strdup("DIV");
		symbol_table[count].data_type=strdup("Keyword");
		symbol_table[count].line_no=line+1;
		count++;
		return _DIV;									
	}
\(		{ return _OPEN_BRACE;								}
\)		{ return _CLOSE_BRACE;								}
{id}		{ yylval.ID = install_id();  return _ID;					}
{int}		{ yylval.NUMBER.type = 0; yylval.NUMBER.integer = install_int(); return _INT;	}
{real}		{ yylval.NUMBER.type = 1; yylval.NUMBER.real = install_real(); return _FLOAT;	}
.		{ flag=0; printf("error: unexpected character syntax error, line number: %d\n", line + 1);	}
%%

char* install_id() {
	for(int i = 0; i < NUM_KEYWORDS; i++) {
        if(strcmp(keywords[i], yytext) == 0) {
            printf("error: Can't use reserved keyword '%s' as variable name, line number: %d\n", yytext, line + 1);
            return NULL;
        }
    }
	symbol* sym = search(&SYMTAB,yytext);
	if(sym == NULL)
		sym = insert(&SYMTAB,yytext, 'V');
	symbol_table[count].id_name=strdup(yytext);
	symbol_table[count].data_type=strdup("variable");
	symbol_table[count].line_no=line+1;
	count++;
	return strdup(yytext);
}

int install_int() {
	symbol_table[count].id_name=strdup(yytext);
	symbol_table[count].data_type=strdup("Integer");
	symbol_table[count].line_no=line+1;
	count++;
	return atoi(yytext);
}

float install_real() {
	symbol_table[count].id_name=strdup(yytext);
	symbol_table[count].data_type=strdup("Real Number");
	symbol_table[count].line_no=line+1;
	count++;
	return atof(yytext);
}


