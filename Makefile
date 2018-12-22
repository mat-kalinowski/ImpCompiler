.PHONY: default

WORK_DIR=./build
OUT_DIR=./bin

default: out_dir work_dir compiler

clean:
	rm -rf ./build
	rm -rf ./bin

compiler: parser lexer
	cp *.h $(WORK_DIR)
	g++-7 -o $(OUT_DIR)/compiler $(WORK_DIR)/lex.cpp $(WORK_DIR)/parser.tab.c

lexer: lexer.l
	flex -o $(WORK_DIR)/lex.cpp lexer.l

parser: parser.y
	bison --defines=$(WORK_DIR)/parser.tab.h -o $(WORK_DIR)/parser.tab.c parser.y

out_dir:
	mkdir -p $(OUT_DIR)

work_dir:
	mkdir -p $(WORK_DIR)
