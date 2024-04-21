TO RUN:
1. lex ans.l
2. yacc -d ans.y 
3. cc lex.yy.c y.tab.c 
./a.out < input.pas
./a.out < input1.pas
./a.out < input2.pas

input.pas has the correct program and input1.pas and input2.pas are variations of the program with semantic errors.

ERRORS:
I have handled the following semantic errors:
1. Duplicate declaration
2. Missing declaration
3. Missing initialization
4. Type Mismatch
5. Variables are not reserved words

The first command invokes Lex, a lexical analyzer generator, with the input file ans.l. Lex reads the file ans.l, which contains specifications for tokenizing input text, and generates a C source file named lex.yy.c which contains the lexical analyzer code based on the rules specified in ans.l. The second command invokes Yacc, a parser generator, with the input file ans.y. Yacc reads the file ans.y, which contains the grammar specification for the language being parsed, and generates C source files y.tab.c and y.tab.h. The -d option tells Yacc to generate header file y.tab.h which contains token definitions. The third command invokes a C compiler to compile the generated Lex and Yacc files. lex.yy.c contains the lexical analyzer code generated by Lex, and y.tab.c contains the parser code generated by Yacc. The compiler compiles these source files into an executable program.