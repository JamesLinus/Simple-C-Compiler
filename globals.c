#include <stdlib.h>
#include "types.h"
#include <stdbool.h>

int current_line=0;
int current_char=0;
char *current_file=NULL;
int yydebug=0;

bool evaluate_constants=false;

struct type_t **types=NULL;
int num_types=0;

struct var_t **vars=NULL;
int num_vars=0;

struct func_t **funcs=NULL;
int num_funcs=0;

int scope=0;
