INCLUDE=../include
include ../include/config.mk

../generator.a: generator-misc.o generator-globals.o  generator-expr.o generator-statem.o
	$(AR)

.PHONY:
clean:
	rm lex.yy.c 2>/dev/null || true
	rm comp.tab.c 2>/dev/null || true
	rm include/comp.tab.h 2>/dev/null || true
	rm *.o 2>/dev/null || true
	rm main 2>/dev/null || true
	rm *.a 2>/dev/null || true
