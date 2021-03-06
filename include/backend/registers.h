#ifndef __REGISTERS_H__
#define __REGISTERS_H__
#include "types.h"
#include <stdio.h>
#include "generator/generator-types.h"

extern char* get_reg_name(struct reg_t *reg, size_t size);
extern struct reg_t* get_ret_register(size_t s);
extern struct reg_t* get_free_register(FILE *fd, size_t s, int depth);
extern void free_register(FILE *fd, struct reg_t *r);
extern char* reg_name(struct reg_t *a);
extern void set_register_size(struct reg_t *r, size_t s);

#endif
