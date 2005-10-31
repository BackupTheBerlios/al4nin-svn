### when compiling this on dengsvr06, we need to
### use a special g++ compiling down to 32-bit
### then we can simply ddd on the binary.

naive: ../include/alloc.hpp ../src/alloc.cpp naive.cpp
	/opt/exp/gnu/sparc-sun-solaris2.8/bin/g++ -g -lrt -I ../include -I ../src -o naive naive.cpp

