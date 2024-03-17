%{
	/* header files */
	#include<stdio.h>
	#include<stdlib.h>
	#include<string.h>

	/* definitions of manifest constants*/
	#define _PROGRAM	1
	#define _VAR		2
	#define _BEGIN		3
	#define _END		4
	#define _END_DOT	5
	#define _INTEGER	6
	#define _FOR		7
	#define _READ		8
	#define _WRITE		9
	#define _TO		10
	#define _DO		11
	#define _SEMICOLON	12
	#define _COLON		13
	#define _COMMA		14
	#define _ASSIGN		15
	#define _ADD		16
	#define _SUB		17
	#define _MUL		18
	#define _DIV		19
	#define _OPEN_BRACE	20
	#define _CLOSE_BRACE	21
	#define _ID		22
	#define _INT		23

	/* hashtable implementation */
	#define SIZE 20

	typedef struct symbol {
		char* specifier;
		char type;
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
		for(int i = 0; i < len; i++) 
			hash += (int) specifier[i];
		return hash % SIZE;
	}

	void init() {
		// initialize all bucket to null
		for (int i = 0; i < SIZE; i++) {
        	SYMTAB.buckets[i] = NULL;
    	}
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
		new_symbol -> type = type;
		new_symbol->next = NULL;
		return new_symbol;
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

	void print() {
		// pretty printing of hash table
		printf("-------------------------------------\n");
		printf("SYMTAB\n");
		for(int i = 0; i < SIZE; i++) {
			printf("bucket [%d]: ", i);
			symbol* temp = SYMTAB.buckets[i];
			while(temp != NULL) {
				printf("%c%s -> ", temp -> type, temp -> specifier);
				temp = temp -> next;
			}
			printf("NULL\n");
		}
		printf("-------------------------------------\n");
	}

	
	/* declaration of useful functions and variables */
	void* yylval;
	void* install_id();
	void* install_num();
	int line = 0;
%}

delim		[ \t\n]
letter		[A-Za-z]
digit		[0-9]
id		{letter}({letter}|{digit})*
int		{digit}+

%%
\n		{ line++;					}
[ \t]		{						}
PROGRAM		{ return _PROGRAM ;				}
VAR		{ return _VAR ;					}
BEGIN		{ return _BEGIN ;				}
END		{ return _END ;					}
END\.		{ return _END_DOT ;				}
INTEGER		{ return _INTEGER ;				}
FOR		{ return _FOR ;					}
READ		{ return _READ;					}
WRITE		{ return _WRITE ;				}
TO		{ return _TO;					}
DO		{ return _DO;					}
\;		{ return _SEMICOLON;				}
\:		{ return _COLON;				}
\,		{ return _COMMA;				}
\:\=		{ return _ASSIGN;				}
\+		{ return _ADD;					}
\-		{ return _SUB;					}
\*		{ return _MUL;					}
DIV		{ return _DIV;					}
\(		{ return _OPEN_BRACE;				}
\)		{ return _CLOSE_BRACE;				}
{id}		{ yylval = (void*)install_id();  return _ID;	}
{int}		{ yylval = (void*)install_num(); return _INT;	}
%%

void* install_id() {
	symbol* sym = search(&SYMTAB,yytext);
	if(sym == NULL)
		sym = insert(&SYMTAB,yytext, '^');
	return sym;
}

void* install_num() {
	symbol* sym = search(&SYMTAB,yytext);
	if(sym == NULL)
		sym = insert(&SYMTAB,yytext, '#');
	return sym;
}


int main() {
	init();

	int token;
	int prev_line = 0;

	/* parsing the every token of the input program */
	token = yylex();
	while(token) {

		/* printing the line number */
		if(line == 0) {
			line++;
			printf("%10d", line);
		} else {
			if(line == prev_line)
				printf("%10c", ' ');
			else
				printf("%10d", line);
		}


		/* printing the token id, type and specifier */
		if(token == 22 || token == 23){
			symbol* sym = NULL;
			sym = (symbol *)yylval;
			printf("%10d %10c%s\n", token, sym -> type, sym -> specifier);
		}
		else
			printf("%10d \n", token);
		
		prev_line = line;
		token = yylex();
	}

	print();
	return 0;
}
