%{
	#include "data.h"

	#include <iostream>
	#include <unordered_map>
	#include <string>
	#include <vector>

	using namespace std;

  extern int yylex();
	extern int yyparse();
	extern FILE *yyin;

	void yyerror(const char *s);
	void add_symbol(string name, bool simple);
	void set_symbol_value(string name, int value);
	void gen_const(int value, reg_label acc);
	reg_label allocate_var(symbol &var);
	void push_command(string command);
	symbol get_var(string name);

	unordered_map <string,symbol> symbol_tabel;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false}};
%}

%union{
	int ival;
	char* sval;
}
%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN EQ
%token LB RB
%token <sval> PIDENTIFIER
%token <ival> NUM

%type <sval> identifier;

%%

program: DECLARE declarations IN commands END {
	push_command("HALT");

  for(int i =0; i < output_code.size(); i++){
		cout << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { add_symbol((string) $2, true); } |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM { add_symbol((string) $2, false); } |
;

commands: commands command |
 					command
;

command: identifier ASN NUM SEM {set_symbol_value((string)$1,$3); }
;

command: READ identifier SEM {}
;

command: WRITE identifier SEM {push_command("PUT " + (string)label_str[get_var($2).curr_reg]);}
;

identifier: PIDENTIFIER |
						PIDENTIFIER LB PIDENTIFIER RB |
						PIDENTIFIER LB NUM RB
;

%%

void add_symbol(string name, bool simple){
	symbol new_symbol(simple);
	symbol_tabel.insert({name,new_symbol});
}

symbol get_var(string name){
	unordered_map<string,symbol>::iterator it = symbol_tabel.find(name);
	reg_label temp;

	if(it != symbol_tabel.end()){
		return it->second;
	}

	return NULL;
}

void set_symbol_value(string name, int value){
	unordered_map<string,symbol>::iterator it = symbol_tabel.find(name);
	reg_label temp;

	if(it == symbol_tabel.end()){
		return;
	}
	else{
		temp = allocate_var(it->second);
		gen_const(value,temp);
	}
}

reg_label allocate_var(symbol &var){
	var.initialized = true;

	for(int i = 0; i < registers.size(); i++){
		if(!registers[i].taken){
			registers[i].taken = true;
			var.curr_reg = registers[i].label;
		}
	}
	return var.curr_reg;
}

void gen_const(int value, reg_label acc){
	int curr = 2;
	string reg_str = label_str[acc];

	output_code.push_back("SUB "+ reg_str + " " + reg_str);
	output_code.push_back("INC "+ reg_str);

	while(curr < value){
		output_code.push_back("ADD "+ reg_str + " " + reg_str);
		curr *= 2;
	}
	if(curr != value){
		curr /= 2;
		while(curr != value){
			output_code.push_back("INC "+ reg_str);
			curr++;
		}
	}
}

void push_command(string command){
	output_code.push_back(command);
}

int main (int argc, char **argv){
	if(argc > 0){
			FILE *file = fopen(argv[1], "r");

			if (!file) {
			 cout << "cannot open file " << argv[1] << endl;
			 return -1;
		 	}
			yyin = file;
	}

	else{
		yyin = stdin;
	}

	yyparse();
}

void yyerror(const char *s) {
  cout << "parse error " << s << endl;
  exit(-1);
}
