### when compiling this on dengsvr06, we need to
### use a special g++ compiling down to 32-bit
### then we can simply ddd on the binary.

G++ = /opt/exp/gnu/sparc-sun-solaris2.8/bin/g++

naive: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	$(G++) -g -lrt -lpthread -I ../include -I ../src -o naive naive.cpp

warnings: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	$(G++) -c -Wall -I ../include -I ../src -o warnings naive.cpp

all: ct-regression-test naive

ct-regression-test: ct-regressions.o

ct-regressions.o: ../include/alloc.hpp ct-regressions.cpp
	$(G++) -c -I ../include ct-regressions.cpp

mac: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	g++ -g -I ../include -I ../src -o naive naive.cpp

bench: ../include/alloc.hpp GCBench.cpp
	$(G++) -Wall -I ../include -o bench GCBench.cpp

gc-bench: ../include/alloc.hpp GCBench.cpp
	$(G++) -Wall -I ../include -I $(HOME)/include -L$(HOME)/lib -lgc -DGC -o gc-bench GCBench.cpp
