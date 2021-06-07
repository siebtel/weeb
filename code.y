%{

#include <stdio.h>
#include <stdlib.h>
#include "code.h"

extern FILE *yyin;
extern FILE *yyout;

int yylex(void);
void yyerror(char *);

int current_max_reg, current_labels;
var variables[MAXREG];

%}

%union {
    int iValue;
    float fValue;
    char *sValue;
    char varname;
    expression *exp;
    char *statement;
};

%token <iValue> INTEGER 
%token <fValue> FLOAT
%token <sValue> STRING
%token <varname> VARIABLE
%left '+' '-'
%left '*' '/' '>' '<' EQ NE GE LE
%left IF ELSE WHILE READ PRINT VARINTEGER VARFLOAT

%type <exp>  expr
%type <statement> statement list_statement

%%

program:
        program list_statement          {fprintf(yyout, "%s", completeCProgram($2));}             
        |
        ;

statement:
        expr                            {$$ = expressionToStatement($1, EXPRS);}                    
        | VARINTEGER VARIABLE           {$$ = allocation($2, VINT);}
        | VARFLOAT VARIABLE             {$$ = allocation($2, VFLOAT);}
        | VARIABLE '=' expr             {var *temp = vquery($1); char *buffer = expressionToStatement($3, ATTS); $$ = atributionStatement(temp->reg, buffer);}
        | READ VARIABLE                 {var *temp = vquery($2); $$ = readStatement(temp);}
        | PRINT expr                    {$$ = expressionToStatement($2, PRINTS);}
        | PRINT STRING                  {$$ = concat("printf\(\"%s\\n\"\, \"", $2 ,"\"\)\;\n");}
        | IF expr '[' '\n' list_statement ']' '\n'   {$$ = ifStatement($2, $5);}
        | IF expr '[' '\n' list_statement ']' '\n' ELSE '[' '\n' list_statement ']' {$$ = ifElseStatement($2, $5, $11);}
        | WHILE expr '[' '\n' list_statement ']' {$$ = whileStatement($2, $5);}
        ;

list_statement:
        statement                       {$$ = $1;}
        | statement '\n' list_statement {$$ = concat($1, "", $3);}
        | list_statement list_statement {$$ = concat($1, "\n", $2);}
        ;

expr:
    INTEGER                             { $$ = intToExpression($1); }
    | FLOAT                             { $$ = floatToExpression($1); }
    | VARIABLE                          { var *temp = vquery($1); $$ = varToExpression(temp); }
    | expr '+' expr                     { $$ = basicOpr($1, $3, charToString('+'));}
    | expr '-' expr                     { $$ = basicOpr($1, $3, charToString('-'));}
    | expr '/' expr                     { $$ = basicOpr($1, $3, charToString('/'));}
    | expr '*' expr                     { $$ = basicOpr($1, $3, charToString('*'));}
    | expr '>' expr                     { $$ = basicOpr($1, $3, charToString('>'));}
    | expr '<' expr                     { $$ = basicOpr($1, $3, charToString('<'));}
    | expr EQ expr                      { $$ = basicOpr($1, $3, "==");}
    | expr NE expr                      { $$ = basicOpr($1, $3, "!=");}
    | expr GE expr                      { $$ = basicOpr($1, $3, ">=");}
    | expr LE expr                      { $$ = basicOpr($1, $3, "<=");}
    | '(' expr ')'                      { $2->expressionStr = concat("(", $2->expressionStr ,")"); $$ = $2;}
    ;


%%

void yyerror(char *s){
    fprintf(stderr, "%s\n", s);
    return 0;
}

void parse(FILE* fileInput, FILE* fileOutput){
    yyin= fileInput;
    yyout= fileOutput;
    while(feof(yyin)==0)
    {
    yyparse();
    }
}

int fhash(char c){
    return (int)c-'a';
}

char fhash_reverse(int x){
    return (char)('a'+x);
}

char* allocation(char c, types type){
    char *buffer;
    char *tempbuffer;
    int size = 1;
    int index = fhash(c);
    if(variables[index].reg == NULL){
        variables[index].type = type;
        variables[index].reg = concat("r", intToString(current_max_reg++), "");
        tempbuffer = temporaryStringBuffer(variables[index].reg);
        switch(type){
            case VINT:
                buffer = concat("int ", tempbuffer, "\;\n");
                break;
            case VFLOAT:
                buffer = concat("float ", tempbuffer, "\;\n");
                break;
            default:
                yyerror("tipo nao definido! baka!\n");
                break;
        }
        return buffer;
    }
    else{
        yyerror("variavel ja alocada! baka!");
    }
}

var *vquery(char c){
    int index = fhash(c);
    var *variable = &variables[index];
    if(variable->reg == NULL) yyerror("Variavel nao alocada! baka!");
    return variable;
}

char *cs(types type){ //sequencia de conversao
    char *buffer;
    buffer = (char*)malloc(sizeof(char)*3);
    buffer[0] = '%'; buffer[2] = '\0';
    switch(type){
        case VINT:
            buffer[1] = 'd';
            break;
        case VFLOAT:
            buffer[1] = 'f';
            break;
    }
    return buffer;
    
}

expression *intToExpression(int x){
    expression* expr = (expression*)malloc(sizeof(expression));
    expr->type = VINT;
    expr->expressionStr = intToString(x);
    return expr;
}

expression *floatToExpression(float x){
    expression* expr = (expression*)malloc(sizeof(expression));
    expr->type = VFLOAT;
    expr->expressionStr = floatToString(x);
    return expr;
}

expression *varToExpression(var *v){
    expression* expr = (expression*)malloc(sizeof(expression));
    expr->type = v->type;
    expr->expressionStr = v->reg;
    return expr;
}

expression *basicOpr(expression *exp1, expression *exp2, char* bo){
    char *buffer1, *buffer2;
    buffer1 = temporaryStringBuffer(exp1->expressionStr);
    buffer2 = temporaryStringBuffer(exp2->expressionStr);
    expression* expr = (expression*)malloc(sizeof(expression));
    if(exp1->type == VFLOAT || exp2->type == VFLOAT) expr->type = VFLOAT;
    else expr->type = VINT;
    expr->expressionStr = concat(buffer1, bo , buffer2);
    return expr;
}

char *expressionToStatement(expression *expr, statement_type type){
    char* buffer;
    int size;
    switch(type){
        case ATTS:
        case EXPRS:
            size = strlen(expr->expressionStr);
            buffer = (char*)malloc(size+1);
            buffer = expr->expressionStr;
            break;
        case PRINTS:
            switch(expr->type){
                case VINT:
                    buffer = concat("printf\(\"%d\\n\"\, ", temporaryStringBuffer(expr->expressionStr) ,"\)\;\n");
                    break;
                case VFLOAT:
                    buffer = concat("printf\(\"%f\\n\"\, ", temporaryStringBuffer(expr->expressionStr) ,"\)\;\n");
                    break;

            }
    }
    return buffer;
}

char *atributionStatement(char* reg, char* expr){
    char *buffer1, *buffer2, *buffer;
    buffer1 = temporaryStringBuffer(reg);
    buffer2 = temporaryStringBuffer(expr);
    buffer = concat(buffer1, " = ", concat(buffer2, "\;\n", ""));
    return buffer;
}

char *readStatement(var* var){
    char *buffer;
    switch(var->type){
        case VINT:
            buffer = concat("scanf\(\"%d\"\, \&", temporaryStringBuffer(var->reg), "\)\;\n");
            break;
        case VFLOAT:
            buffer = concat("scanf\(\"%f\"\, \&", temporaryStringBuffer(var->reg), "\)\;\n");
            break;
    }
    return buffer;
}

char *ifStatement(expression* expr, char* statement){
    char **L = (char**)malloc(sizeof(char*)*2);
    for(int i=0; i<2; i++){
        L[i] = concat("L", intToString(current_labels++), "");
    }
    char *header = concat("if(", temporaryStringBuffer(expr->expressionStr), ") ");
    char *trueExpr = concat("goto ", temporaryStringBuffer(L[0]), ";\n");
    char *falseExpr = concat("goto ", temporaryStringBuffer(L[1]), ";\n");
    char *completeHeader = concat(header, trueExpr, falseExpr);
    char *list = concat(temporaryStringBuffer(L[0]), ": ", temporaryStringBuffer(statement));
    char *endIf = concat(temporaryStringBuffer(L[1]), ":", "");
    char *ifStr = concat(completeHeader, list, endIf);
    return ifStr;
}

char *ifElseStatement(expression* expr, char* statement1, char* statement2){
    char **L = (char**)malloc(sizeof(char*)*3);
    for(int i=0; i<3; i++){
        L[i] = concat("L", intToString(current_labels++), "");
    }
    char *header = concat("if(", temporaryStringBuffer(expr->expressionStr), ") ");
    char *goto1 = concat("goto ", temporaryStringBuffer(L[0]), ";\n");
    char *goto2 = concat("goto ", temporaryStringBuffer(L[1]), ";\n");
    char *goto3 = concat("goto ", temporaryStringBuffer(L[2]), ";\n");
    char *label1 = concat(temporaryStringBuffer(L[0]), ":", "");
    char *label2 = concat(temporaryStringBuffer(L[1]), ":", "");
    char *label3 = concat(temporaryStringBuffer(L[2]), ":", "");

    char *completeHeader = concat(header, goto1, goto2);
    char *list1 = concat(label1, statement1, goto3);
    char *list2 = concat(label2, statement2, label3);

    char *ifElseStr = concat(completeHeader, list1, list2);

    return ifElseStr;
}

char *whileStatement(expression* expr, char* statement){
    char **L = (char**)malloc(sizeof(char*)*3);
    for(int i=0; i<3; i++){
        L[i] = concat("L", intToString(current_labels++), "");
    }
    char *header = concat("if(", temporaryStringBuffer(expr->expressionStr), ") ");
    char *goto1 = concat("goto ", temporaryStringBuffer(L[0]), ";\n");
    char *goto2 = concat("goto ", temporaryStringBuffer(L[1]), ";\n");
    char *goto3 = concat("goto ", temporaryStringBuffer(L[2]), ";\n");
    char *label1 = concat(temporaryStringBuffer(L[0]), ":", "");
    char *label2 = concat(temporaryStringBuffer(L[1]), ":", "");
    char *label3 = concat(temporaryStringBuffer(L[2]), ":", "");

    char *completeHeader = concat(label2, header, goto1);
    char *list = concat(label1, statement, goto2);
    char *jump = concat(goto3, list, label3);

    char *whileStr = concat(completeHeader, jump, "");

    return whileStr;
}

char *completeCProgram(char* program){
    char *header = "#include <stdio.h>\n\nint main(){\n";
    char *footer = "\nreturn 0;\n}";
    char *complete_program = concat(header, program, footer);
    return complete_program;
}


void init(){
    current_max_reg = 0;
    current_labels = 0;
    for(int i=0; i<MAXREG; i++){
        variables[i].reg = NULL;
        variables[i].type = VINT;
    }
}

char *intToString(int value){
	char *buffer;
	buffer = (char*)malloc(11);
	if(buffer == NULL){
		fprintf(stderr, "Could not malloc\n");
		exit(EXIT_FAILURE);
	}
	sprintf(buffer, "%d", value);
	return buffer;
}

char *floatToString(float value){
	char *buffer;
	buffer = (char*)malloc(100);
	if(buffer == NULL){
		fprintf(stderr, "Could not malloc\n");
		exit(EXIT_FAILURE);
	}
	sprintf(buffer, "%f", value);
	return buffer;
}

char *charToString(char c){
    char *buffer;
    buffer = (char*)malloc(sizeof(char)*2);
    buffer[0] = c; buffer[1] = '\0';
    return buffer;
}

char *concat(char *a, char *b, char *c){
	int size = 1;
	if(a != NULL) size +=strlen(a);
	if(b != NULL) size +=strlen(b);
	if(c != NULL) size +=strlen(c);
	if( size == 1) return NULL;
	char *buffer;
	buffer = (char*)malloc(size);
	if(buffer == NULL){
		fprintf(stderr, "Could not malloc\n");
		exit(EXIT_FAILURE);
	}
	//buffer = '\0';
	if(a != NULL){
		strcpy(buffer, a);
		//free(a); problema com linux      
	}
	if(b != NULL){
		strcat(buffer, b);
		//free(b); problema com linux
	} 
	if(c != NULL){
		strcat(buffer, c);
		//free(c); problema com linux
	} 

	return(buffer);
}

char* temporaryStringBuffer(char* str){
    char *buffer;
    buffer = (char*)malloc(strlen(str));
    strcpy(buffer, str);
    return buffer;
}

int main(int argc,char* argv[]){

    init();

    FILE* fileInput;
    FILE* fileOutput;
    char inputBuffer[36];
    char lineData[36];

    if((fileInput=fopen(argv[1],"r"))==NULL)
        {
        printf("Error reading files, the program terminates immediately\n");
        exit(0);
        }
    if((fileOutput=fopen(argv[2],"w+"))==NULL)
    {
        printf("No files given, the program terminates immediately\n");
        exit(0);
    }
    parse(fileInput, fileOutput);
}