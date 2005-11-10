### when compiling this on dengsvr06, we need to
### use a special g++ compiling down to 32-bit
### then we can simply ddd on the binary.

G++ = /opt/exp/gnu/sparc-sun-solaris2.8/bin/g++

naive: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	$(G++) -g -lrt -lpthread -I ../include -I ../src -o naive naive.cpp

all: ct-regression-test naive

ct-regression-test: ct-regressions.o

ct-regressions.o: ../include/alloc.hpp
	$(G++) -c -I ../include ct-regressions.cpp

mac: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	g++ -g -I ../include -I ../src -o naive naive.cpp

