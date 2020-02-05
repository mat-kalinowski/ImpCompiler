.PHONY: default

WORK_DIR=./build
OUT_DIR=./bin
SRC_DIR=./src
HDRS_DIR=./headers

default: out_dir work_dir compiler

dependencies:


clean:
	rm -rf ./build
	rm -rf ./bin

compiler: parser lexer
	cp $(HDRS_DIR)/*.h $(WORK_DIR)
	g++-7 -o $(OUT_DIR)/compiler $(WORK_DIR)/lex.cpp $(WORK_DIR)/parser.tab.c $(SRC_DIR)/*.cpp

lexer:
	flex -o $(WORK_DIR)/lex.cpp $(SRC_DIR)/lexer.l

parser:
	bison --defines=$(WORK_DIR)/parser.tab.h -o $(WORK_DIR)/parser.tab.c $(SRC_DIR)/parser.y

out_dir:
	mkdir -p $(OUT_DIR)

work_dir:
	mkdir -p $(WORK_DIR)
