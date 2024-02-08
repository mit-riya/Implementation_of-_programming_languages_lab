#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define no_op 23

void intToHex6(int num, char* hexString) {
    // converts integer to hex string with 6 digits
    sprintf(hexString,"%X", num);
}

void intToHex4(int num, char* hexString) {
    // converts integer to hex string with 4 digits
    sprintf(hexString,"%04X", num);
}

int min(int a,int b){
    // returns min of 2 numbers
    if(a<b)return a;
    return b;
}

int main(){
    FILE *f=fopen("inp.txt","r");
    FILE *f1=fopen("temp.txt","w");
    char line[500];                   // for reading file line by line
    char* label, *operand, *opcode;   // storing the label,opcode and operand in each instruction
    char* symtab_label[1000];   // part of symbol table map
    int symtab_address[1000];   // part of symbol table map
    char* optab[]={"LDA","LDX","LDL","STA","STX","STL","LDCH","STCH","ADD","SUB","MUL","DIV","COMP","J","JLT","JEQ","JGT","JSUB","RSUB","TIX","TD","RD","WD"};
    char* ophex[]={"00","04","08","0C","10","14","50","54","18","1C","20","24","28","3C","38","30","34","48","4C","2C","E0","D8","DC"};
    int no_labels=0;       // number of entries in symbol table
    int LOCCTR=0;          // current instruction address
    int start_address=0;   // stores starting address fo latr use
    int resb[1000];        // stores jump address after resb instruction 
    int resb_cnt=0;        // number of elements in resb array
    char program_name[7];  // stores program name
    // PASS 1 OF ASSEMBLER
    while(fgets(line, sizeof(line), f)){
        // read input file line by line
        char* token = strtok(line, " \t\n");
        label="";operand=""; opcode="";
        char* ins[30];      // stores all space separated words
        int i=0;     // no of space separated words
        int flag=0;    // used to check for comment line
        while( token != NULL ) {
            // read the line word by word and store all words in ins
            ins[i]=token;
            if(ins[i][0]=='.')flag=1;
            i++;
            token = strtok(NULL, " \n\t");
        }
        // ignore comment lines
        if(flag)continue;
        // store label, opcode and operand
        if(i>=3){
            label=ins[0];
            opcode=ins[1];
            operand=ins[2];
            for(int j=3;j<i;j++){
                strcat(operand,ins[j]);
            }
        }
        else if(i==2){
            opcode=ins[0];
            operand=ins[1];
        }
        else {
            opcode=ins[0];
        }
        if(strcmp(opcode,"START")==0){
            // initialize LOCCTR and start_address in start instruction
            int n=strlen(operand);
            for(int i=0;i<n;i++){
                LOCCTR*=16;
                if(operand[i]>=48 && operand[i]<=57){
                    LOCCTR+=(operand[i]-'0');
                }
                else{
                    LOCCTR+=(operand[i]-55);
                }
            }
            start_address=LOCCTR;
            // store program name
            for(int i=0;i<min(6,strlen(label));i++){
                program_name[i]=label[i];
            }
            continue;
        }
        // store opcode and operand in intermediate file
        fprintf(f1,"%s %s\n",opcode,operand);
        if(strcmp(label,"")){
            // if label is not null
            int fl=0;   // to check if label already exists
            for(int i=0;i<no_labels;i++){
                if(strcmp(label,symtab_label[i])==0){
                    fl=1;
                }
            }
            if(!fl){
                // add label to symbol table
                symtab_label[no_labels] = (char*)malloc(strlen(label) + 1);
                strcpy(symtab_label[no_labels],label);
                symtab_address[no_labels]=LOCCTR;
                no_labels++;
            }
            else{
                printf("Duplicate symbol");
                return 0;
            }
        }
        int opcode_present=0;      // checks if opcode present in table
        for(int i=0;i<no_op;i++){
            if(strcmp(optab[i],opcode)==0)opcode_present=1;
        }
        if(opcode_present)LOCCTR+=3;       
        else if(strcmp(opcode,"WORD")==0)LOCCTR+=3;
        else if(strcmp(opcode,"RESW")==0){
            LOCCTR+=(3*atoi(operand));
            resb[resb_cnt++]=LOCCTR;    // store jump address
        }
        else if(strcmp(opcode,"RESB")==0){
            LOCCTR+=atoi(operand);
            resb[resb_cnt++]=LOCCTR;    // store jump address
        }
        else if(strcmp(opcode,"BYTE")==0){
            // find length of constant in bytes, add length to LOCCTR
            if(operand[0]=='C'){
                int x=strlen(operand)-3;
                LOCCTR+=x;
            }
            else{
                int x=strlen(operand)-3;
                LOCCTR+=((x+1)/2);
            }
        }
        else if(strcmp(opcode,"END") && strcmp(opcode,"")){
            printf("Invalid operation code");
            return 0;
        }
    }
    int program_length=LOCCTR-start_address;    // store program length
    fclose(f1);
    // PASS 2 OF ASSEMBLER
    FILE* ptr=fopen("temp.txt","r");
    char ar[1000][30];                // stores machine code of each instruction
    int ins_cnt=0;                    // stores number of instructions
    while(fgets(line, sizeof(line), ptr)){
        int p=0;        // no of characters in ar[ins_cnt]
        char* token = strtok(line, " ");
        operand=""; opcode="";
        char* ins[20];
        int i=0;
        while( token != NULL ) {
            ins[i]=token;
            i++;
            token = strtok(NULL, " \n");
        }
        opcode=ins[0];
        operand=ins[1];
        int ind=-1;      // gets index of opcodes in optable
        int present=0;   // indicates if opcode is present in optable
        // search optab for opcode
        for(int i=0;i<no_op;i++){
            if(strcmp(optab[i],opcode)==0){
                ind=i;
                present=1;
            }
        }
        // if opcode found
        if(present){
            // store opcode 
            ar[ins_cnt][p++]=ophex[ind][0];  
            ar[ins_cnt][p++]=ophex[ind][1];
            int opcode_present=-1;       // index at which operand is present in symbol table
            char hexString[]={"0000"};   
            int n=strlen(operand); 
            // search symtab for operand
            for(int i=0;i<no_labels;i++){
                if(n>=2 && operand[n-1]=='X' && operand[n-2]==','){
                    char temp[n-1];
                    for(int j=0;j<n-2;j++){
                        temp[j]=operand[j];
                    }
                    temp[n-2]='\0';
                    if(strcmp(symtab_label[i],temp)==0)opcode_present=i;
                }
                if(strcmp(symtab_label[i],operand)==0)opcode_present=i;
            }  
            if(opcode_present!=-1){
                // if found, then store symbol value as operand address
                int decimalNumber = symtab_address[opcode_present];
                if(n>=2 && operand[n-1]=='X' && operand[n-2]==','){
                    decimalNumber+=(1<<15);
                }
                intToHex4(decimalNumber, hexString);
            }
            else if(strcmp(operand,"")){
                printf("Undefined label");
                return 0;
            }
            // assemble the object code instruction
            strcat(ar[ins_cnt],hexString);
            ins_cnt++;
        }
        // else if opcode is "BYTE" or "WORD", then convert constant to object code
        else if(strcmp(opcode,"WORD")==0){
            // assemble the object code instruction
            char hexString[6];
            intToHex6((atoi)(operand),hexString);
            int n=strlen(hexString);
            for(int i=0;i<6-n;i++){
                ar[ins_cnt][p++]='0';
            }
            if(n<6)strcat(ar[ins_cnt],hexString);
            else strcpy(ar[ins_cnt],hexString);
            ins_cnt++;
        }
        else if(strcmp(opcode,"BYTE")==0){
            // assemble the object code instruction
            int n=strlen(operand);
            if(operand[0]=='X'){
                for(int i=2;i<n-1;i++){
                    ar[ins_cnt][p++]=operand[i];
                }
            }
            else{
                int fl=1;
                for(int i=2;operand[i]!='\'';i++){
                    char hexString[2];
                    intToHex6((int)(operand[i]),hexString);
                    if(fl){
                        strcpy(ar[ins_cnt],hexString);
                        fl=0;
                    }
                    else{
                        strcat(ar[ins_cnt],hexString);
                    }
                }
            }
            ins_cnt++;
        }
        else if(strcmp(opcode,"RESB")==0){
            strcpy(ar[ins_cnt],"&");
            ins_cnt++;
        }
        else if(strcmp(opcode,"RESW")==0){
            strcpy(ar[ins_cnt],"&");
            ins_cnt++;
        }
    }
    for(int i=strlen(program_name);i<6;i++)program_name[i]=' ';
    // printing the object code
    // printing header record
    if(ins_cnt!=0){
        printf("H'%s'",program_name);
        printf("%06X'%06X\n",start_address,program_length);
        printf("T'%06X'",start_address);
        char temp[81];    // stores one line in object code
        int rec=0;        // counter for looping though all instructions
        int res_tem=0;    // current index in list of addresses after resb instruction
        int prev_add=start_address;  // address used in previous printed line 
        int com_cnt=0;    // for printing apostrophes in output
        while(rec<ins_cnt){
            int n=strlen(ar[rec]);
            if(strcmp(ar[rec],"&")==0){
                // end the current text record on resb instruction and start a new text record
                prev_add=resb[res_tem++];
                if(rec>0 && strcmp(ar[rec-1],"&")){
                    printf("%02X'%s\n",(strlen(temp)-com_cnt)/2,temp);
                }
                if(rec!=ins_cnt-1 && strcmp(ar[rec+1],"&"))
                    printf("T'%06X'",prev_add);
                memset(temp, '\0', sizeof(temp));
                rec++;
                com_cnt=0;
            }
            else if((strlen(temp)+n-com_cnt)<=60){
                // add object code to text record
                if(strlen(temp)==0)strcpy(temp,ar[rec]);
                else strcat(temp,ar[rec]);
                strcat(temp,"'");
                rec++;
                com_cnt++;
            }
            else{
                // if object code will not fit into current text record, then write text record to object program and initialize new text record
                prev_add+=(strlen(temp)-com_cnt)/2;
                // print text record
                printf("%02X'%s\nT'%06X'",(strlen(temp)-com_cnt)/2,temp,prev_add);
                memset(temp, '\0', sizeof(temp));
                com_cnt=0;
            }
        }
        if(strcmp(ar[ins_cnt-1],"&"))
        printf("%02X'%s\n",(strlen(temp)-com_cnt)/2,temp);   // write last text record to object program
        // printing end record
        printf("E'%06X",start_address);
    }
}