#ifndef __TYPES_H__
#define __TYPES_H__
#include <stdbool.h>
#include <stdlib.h>

typedef void (*__printer_function_t) (char*, void*); /* For type conversion for
the print_tree function so I don't get annoying warnings because I never pass it
a function pointer that has void* as the second argument type. */

struct tbody_t {
	size_t size;
	int refcount;
	int base_pointer_depth;
	bool is_struct, is_union, is_func_pointer;
	union {
		struct {
			struct var_t **vars;
			int num_vars;
			size_t alignment;
		} vars;

		struct {
			struct type_t *return_type;
			struct type_t **arguments;
			int num_arguments;
		} func_ptr;
	} attrs;
};

struct type_t {
	bool native_type;
	int refcount;
	char *name;
	int pointer_depth;
	struct tbody_t *body;
};

struct expr_t {
	enum { bin_op, pre_un_op, post_un_op, question, const_int, const_float, var, funccall, arg, const_str, const_size_t, func_val, func_ptr_call } kind;
	struct expr_t *left, *right;
	struct type_t *type;
	bool has_gotos;
	union {
		struct var_t *var;
		long int cint_val;
		char *bin_op;
		char *un_op;
		char *cstr_val;
		struct expr_t *argument;
		struct func_t *function;
	} attrs;
};

struct var_t {
	char *name;
	off_t offset;
	int scope_depth;
	bool hidden;
	struct type_t *type;
	int refcount;
};

struct statem_t {
	enum { expr, list, declare, _while, ret, _if, _break, _continue, label, _goto, _for, do_while, _switch, _case, _default } kind;
	bool has_gotos;
	union {
		char *label_name;
		struct expr_t *expr;
		struct var_t *var;

		struct {
			struct statem_t *block;
			struct expr_t *condition;
			char *label;
		} _case;

		struct {
			struct statem_t **statements;
			int num;
		} list;

		struct {
			struct expr_t *condition;
			struct statem_t *block;
		} _while;

		struct {
			struct expr_t *condition;
			struct statem_t *block;
		} do_while;

		struct {
			struct expr_t *condition;
			struct statem_t *block;

			struct statem_t *else_block;
		} _if;

		struct {
			struct expr_t *initial, *cond, *update;
			struct statem_t *block;
		} _for;

		struct {
			struct statem_t *cases;
			struct expr_t *tester;
		} _switch;
	} attrs;
};

struct func_t {
	char *name;
	enum { _extern, _static, _inline } attributes;
	struct statem_t *statement_list;
	struct type_t *ret_type;
	struct var_t **arguments;
	int num_arguments;
	bool has_var_args;
	bool do_inline;

	int num_calls;
};

#endif
