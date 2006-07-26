terra-incognita: terra-incognita.lid terra-incognita.dylan \
			terra-incognita-exports.dylan \
			um-spec.dylan load-codex.dylan \
			um.o
	d2c terra-incognita.lid

um.o: um.cpp
	g++ -ggdb -c -o um.o um.cpp

clean:
	-rm -f *.o *.s *.a *.c *.mak *~ terra-incognita
	-rm -rf .libs
