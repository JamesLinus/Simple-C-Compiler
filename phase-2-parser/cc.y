%{
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "generator/generator.h"
#include "globals.h"
#include "handle-exprs.h"
#include "handle-funcs.h"
#include "handle-statems.h"
#include "handle-types.h"
#include "handle-vars.h"
#ifdef DEBUG
#include "printer.h"
#include "print-tree.h"
#endif
#include "types.h"

void yyerror(const char *s);
extern int yydebug;
extern FILE* yyin;
FILE *output;

static inline struct expr_t* make_bin_op(char *X, struct expr_t *Y, struct expr_t *Z)
{
	/* TODO: Make sure that integers added to pointers get multiplied by the size of the pointer base type */
	if (strlen(X)==2 && X[1]=='=' && X[0]!='='  && X[0]!='<' && X[0]!='>' && X[0]!='!' ) {
		struct expr_t *assignment=malloc(sizeof(struct expr_t));
		struct expr_t *or=malloc(sizeof(struct expr_t));
		assignment->kind=or->kind=bin_op;
		assignment->attrs.bin_op=strdup("=");
		assignment->type=Y->type;
		Y->type->refcount+=2;
		assignment->left=Y;
		assignment->right=or;

		or->attrs.bin_op=calloc(2, sizeof(char));
		or->attrs.bin_op[1]='\0';
		or->attrs.bin_op[0]=X[0];
		or->type=assignment->type;

		or->left=copy_expression(Y);
		or->right=Z;
		return assignment;
	}
	struct expr_t *e=malloc(sizeof(struct expr_t)); 
	struct expr_t *a=Y, *b=Z;
	parser_type_cmp(&a, &b);
	e->type=a->type;
	e->type->refcount++;
	if (!evaluate_constant_expr(X, a, b, &e)) {
		e->kind=bin_op;
		e->left=a;
		e->right=b;
		e->attrs.bin_op=strdup(X);
	}

	return e;
}

struct type_t *current_type=NULL;

struct arguments_t {
	struct var_t **vars;
	int num_vars;
};

static inline struct statem_t* declare_var(struct type_t *t, char *name, struct expr_t *e)
{
	struct var_t *v=malloc(sizeof(struct var_t));

	v->refcount=4;
	v->type=t;
	v->type->refcount++;
	v->name=strdup(name);
	v->scope_depth=scope_depth;
	v->hidden=false;
	free(name);
	add_var(v);

	struct statem_t *block=malloc(sizeof(struct statem_t));
	struct statem_t *declaration=malloc(sizeof(struct statem_t));

	declaration->kind=declare;
	declaration->attrs.var=v;

	block->kind=list;
	block->attrs.list.num=2;

	int num=2;
	block->attrs.list.statements=calloc(2, sizeof(struct statem_t*));

	struct statem_t *expression=block->attrs.list.statements[1]=malloc(sizeof(struct statem_t));
	expression->kind=expr;
	struct expr_t *assignment=expression->attrs.expr=malloc(sizeof(struct expr_t));
	assignment->kind=bin_op;
	assignment->attrs.bin_op=strdup("=");
	assignment->type=t;
	t->refcount+=2;

	struct expr_t *var_holder=malloc(sizeof(struct expr_t));
	var_holder->kind=var;
	var_holder->type=t;
	t->refcount++;
	var_holder->left=var_holder->right=NULL;
	var_holder->attrs.var=v;
	assignment->left=var_holder;
	assignment->right=e;

	/*TODO add type checking. */
	block->attrs.list.statements[0]=declaration;

	return block;
}
%}
%union {
	long int l;
	struct expr_t *expr;
	struct statem_t *statem;
	struct type_t *type;
	char *str;
	struct func_t *func;
	struct var_t *var;
	struct arguments_t *vars;
	char chr;
}
%define parse.error verbose
%token BREAK SHIFT_LEFT CONTINUE ELSE EQ_TEST IF NE_TEST RETURN STRUCT WHILE GE_TEST LE_TEST FOR INC_OP DO
%token SHIFT_RIGHT EXTERN GOTO TEST_OR TEST_AND DEC_OP TYPEDEF MULTI_ARGS STATIC INLINE SIZEOF
%token POINTER_OP DEFAULT SWITCH CASE ALIGNOF
%token <str> STR_LITERAL 
%token <type> TYPE
%token <str> ASSIGN_OP
%token <l> CONST_INT
%token <str> IDENTIFIER
%token <chr> CHAR_LITERAL
%token UNION
%type <vars> arg_declaration
%type <expr> noncomma_expression expression binary_expr assignable_expr prefix_expr call_arg_list postfix_expr
%type <statem> statement statement_list var_declaration struct_var_declarations
%type <type> type 
%type <type> type_with_stars
%type <func> function function_header
%type <statem> for_loop
%type <statem> var_declaration_start
%type <statem> switch_element switch_list
%type <l> stars

%right '=' ASSIGN_OP
%right '!' '~' INC_OP DEC_OP
%left '?' ':'
%left TEST_OR
%left TEST_AND
%left '|'
%left '^'
%left '&'
%left '<' LE_TEST '>' GE_TEST EQ_TEST NE_TEST
%left SHIFT_LEFT SHIFT_RIGHT
%left '+' '-'
%left '*' '/' '%'
%left '(' ')' '.' POINTER_OP
%nonassoc IFX
%nonassoc ELSE

%%
file: file_entry | file file_entry ;
file_entry:  function {
	add_func($1);
	#ifdef DEBUG
	if (print_trees)
		print_f($1);
	#endif
	if (!$1->do_inline)
		generate_function(output, $1);
} | var_declaration {
	generate_global_vars(output, $1);
} | function_header ';' {
	add_func($1);
	register int x;
	for (x=0; x<$1->num_arguments; x++) {
		free_var($1->arguments[x]);
	}
	free($1->arguments);
	$1->arguments=NULL;
	multiple_functions=true;
} | TYPEDEF type_with_stars IDENTIFIER ';' {
	struct type_t *t=malloc(sizeof(struct type_t));
	memcpy(t, $2, sizeof(struct type_t));
	t->refcount=1;
	t->native_type=true;
	t->name=strdup($3);
	t->body->refcount++;
	free($3);
	add_type(t);
} | type ';' ;


include(functions.m4)
include(for.m4)
include(statements.m4)
include(expressions.m4)
include(variables.m4)
include(types.m4)

%%
void yyerror(const char *s)
{
	fprintf(stderr, "%s: In function '%s':\n", current_file, current_function);
	fprintf(stderr, "%s:%d:%d: %s\n", current_file, current_line, current_char, s);
	fprintf(stderr, "  ");
	char *no_indent=current_line_str;
	if (no_indent!=NULL)
		while ((*no_indent==' ' || *no_indent=='\t' ) && *no_indent!='\0')
			no_indent++;

	if (no_indent!=NULL) {
		fprintf(stderr, "%s\n", no_indent);
		fprintf(stderr, "  ");

		int x;
		for (x=1; x<current_char; x++) {
			fprintf(stderr, " ");
		}
		fprintf(stderr, "^\n");
	}
}

