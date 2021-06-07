%{
#include <stdlib.h>
void yyerror(char *);
#include "code.h"
#include "y.tab.h"

%}

%%

"se" 				return IF;
"senao"				return ELSE;
"enquanto"			return WHILE;

"ler"               return READ;
"escrever"          return PRINT;

"inteiro"           return VARINTEGER;
"flutuante"         return VARFLOAT;

">="                return GE;
"<="                return LE;
"=?="               return EQ;
"=/="               return NE;

[a-z]               {yylval.varname = *yytext; return VARIABLE;}

[0-9]+              {yylval.iValue = atoi(yytext); return INTEGER;}
[0-9]+\.[0-9]+      {yylval.fValue = atof(yytext); return FLOAT;}
\".*\"              {yylval.sValue = create_string(yytext, strlen(yytext)); return STRING;}

[-+()=./*><\n]       {return *yytext;}

"["					{return *yytext;}
"]"					{return *yytext;}

[ \t\n]               ; /* ignorar espacos em branco */

%%

int yywrap(void) {
 return 1;
}

char *create_string(char *s, int l) {
	char *out = (char *)malloc(sizeof(char) * l);
    s[l-1]= '\0';
	strcpy(out, s+1);
	return(out);
}