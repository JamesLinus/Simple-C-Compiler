INCLUDE=../include
include ../include/config.mk

../loader.o: loader.c
	$(CMP)

../exported.o: exported.o
	cp $^ $@

exported.c: list-of-exported-functions.txt
	./update-header.sh

libx64-backend.so: x64/*
	$(MAKE) -C x64/ ../libx64-backend.so

.PHONY:
clean:
	rm *.o 2>/dev/null || true
	rm *.so 2>/dev/null || true
	$(MAKE) -C x64/ clean
