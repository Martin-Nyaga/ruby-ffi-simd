CXX=g++
LINKER_FLAGS=-lm 
CFLAGS_LIB=-shared -fPIC -Wall -O3
CFLAGS_BIN=-O3 -Wall
CFLAGS_DEBUG=-O3 -g -Wall

lib:
	$(CXX) $(CFLAGS_LIB) $(LINKER_FLAGS) -o build/lib.so src/lib.cpp

bin:
	$(CXX) $(CFLAGS_BIN) $(LINKER_FLAGS) -o build/test src/main.cpp

debug:
	$(CXX) $(CFLAGS_DEBUG) $(LINKER_FLAGS) -o build/test src/main.cpp

clean:
	rm build/*
