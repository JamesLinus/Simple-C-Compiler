#ifndef __GENERATOR_H__
#define __GENERATOR_H__
#include "types.h"

extern void setup_types();
extern void setup_generator();
extern size_t word_size;
extern size_t int_size;
extern void generate_expression(FILE *fd, struct expr_t *e);
extern void generate_function(FILE *fd, struct func_t *f);

#endif
