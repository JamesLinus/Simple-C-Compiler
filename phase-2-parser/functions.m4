arg_declaration: type_with_stars IDENTIFIER{
	struct arguments_t *a=malloc(sizeof(struct arguments_t));
	a->vars=calloc(1, sizeof(struct var_t*));
	a->vars[0]=malloc(sizeof(struct var_t));
	struct var_t *v=a->vars[0];
	v->name=strdup($2);
	v->type=$1;
	v->type->refcount++;
	v->scope_depth=1;
	v->hidden=false;
	v->refcount=2;
	a->num_vars=1;
	add_var(v);
	free($2);
	$$=a;
} | arg_declaration ',' type_with_stars IDENTIFIER {
	struct arguments_t *a=$1;
	a->num_vars++;
	a->vars=realloc(a->vars, a->num_vars*sizeof(struct var_t*));
	int n=a->num_vars-1;
	a->vars[n]=malloc(sizeof(struct var_t));
	struct var_t *v=a->vars[n];
	v->scope_depth=1;
	v->hidden=false;
	v->refcount=2;
	v->name=strdup($4);
	v->type=$3;
	v->type->refcount++;
	add_var(v);
	free($4);
	free_type($3);
	$$=a;
};

function_header: type_with_stars IDENTIFIER '(' ')' {
	struct func_t *f=malloc(sizeof(struct func_t));
	init_func(f);
	f->name=strdup($2);
	f->has_var_args=false;
	f->ret_type=$1;
	f->num_arguments=0;
	f->arguments=NULL;
	f->statement_list=NULL;
	f->do_inline=false;
	free(current_function);
	current_function=strdup(f->name);
	free($2);
	$$=f;
} | type_with_stars IDENTIFIER '(' arg_declaration ')' {
	struct func_t *f=malloc(sizeof(struct func_t));
	f->name=strdup($2);
	init_func(f);
	f->ret_type=$1;
	f->do_inline=false;
	$1->refcount++;
	f->arguments=$4->vars;
	f->num_arguments=$4->num_vars;
	free($4);
	free(current_function);
	current_function=strdup($2);
	free($2);
	$$=f;
} | EXTERN function_header {
	$2->attributes|=_extern;
	$$=$2;
} | type_with_stars IDENTIFIER '(' arg_declaration ',' MULTI_ARGS ')' {
	struct func_t *f=malloc(sizeof(struct func_t));
	init_func(f);
	f->name=strdup($2);
	f->ret_type=$1;
	$1->refcount++;
	f->num_arguments=0;
	f->arguments=$4->vars;
	f->num_arguments=$4->num_vars;
	f->has_var_args=true;
	f->statement_list=NULL;
	free($4);
	free(current_function);
	current_function=strdup($2);
	free($2);
	$$=f;
} | STATIC function_header {
	$2->attributes|=_static;
	$$=$2;
} | INLINE function_header {
	$2->attributes|=_inline;
	$$=$2;
};

function: function_header '{' statement_list '}' {
	$1->statement_list=$3;
	$$=$1;
}
