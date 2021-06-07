#define MAXREG 26

#include <string.h>

typedef enum {VINT, VFLOAT} types;

typedef enum {ATTS, PRINTS, READS, IFS, WHILES, EXPRS} statement_type;

typedef struct {
    types type;
    union reg{
        int i;
        float f;
        void *p;
    };
} reg;

typedef struct{
    char* reg;
    types type;
} var;

typedef struct expressionNode{
    char* expressionStr;
    types type;
} expression;

int fhash(char c);
char fhash_reverse(int x);
char *allocation(char c, types type);
void init();

char *create_string(char *s, int l);
char *concat(char *a, char *b, char *c);
char *charToString(char c);
char *intToString(int value);
char *floatToString(float value);
char *expressionToStatement(expression *expr, statement_type type);
char *atributionStatement(char* reg, char* expr);
char *readStatement(var* var);
char* ifStatement(expression* expr, char* statement);
char *ifElseStatement(expression* expr, char* statement1, char* statement2);
char *whileStatement(expression* expr, char* statement);
char *completeCProgram(char* program);

char* temporaryStringBuffer(char* str);

expression *basicOpr(expression *exp1, expression *exp2, char *bo);

char *cs(types type);
var *vquery(char c);

expression *intToExpression(int x);
expression *floatToExpression(float x);
expression *varToExpression(var *c);

