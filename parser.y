%{
	#include "data.h"
	#include "symbol_table.h"

	#include <iostream>
	#include <unordered_map>
	#include <string>
	#include <vector>

	using namespace std;

  extern int yylex();
	extern int yyparse();
	extern FILE *yyin;

	void yyerror(const char *s);
	void assign_value(string name, string value);
	void gen_const(int value, reg_label acc);
	reg_label allocate_var(symbol *var);
	void push_command(string command);

	symbol_table table;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false}};
	long long int mem_pointer = 0;
%}

%union{
	int ival;
	char* sval;
	symbol idval;
}
%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN EQ
%token ADD SUB MOD MUL DIV
%token LB RB
%token <sval> PIDENTIFIER
%token <sval> NUM

%type <sval> identifier;
%type <sval> expression;
%type <idval> value;

%%

program: DECLARE declarations IN commands END {
	push_command("HALT");

  for(int i =0; i < output_code.size(); i++){
		cout << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { table.add_symbol((string) $2, true,1,ID); } |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM { table.add_symbol((string) $2, false,$6-$4,ID); } |
;

commands: commands command |
 					command
;

command: identifier ASN expression SEM {assign_value((string)$1,(string)$3); }
;

command: READ identifier SEM {}
;

command: WRITE identifier SEM {push_command("PUT " + table.reg_str((string)$2));}
;

expression: value |
 						value ADD value |
						value SUB value |
						value MUL value |
						value DIV value |
						value MOD value
;

value: NUM {table.add_symbol((string) $1, true,1,CONST)} |
			 identifier
;

identifier: PIDENTIFIER |
						PIDENTIFIER LB PIDENTIFIER RB |
						PIDENTIFIER LB NUM RB
;

%%

void assign_value(string name, string value){
	reg_label temp;
	symbol* found_symbol = table.get_var(name);

	if(found_symbol == NULL) {
		yyerror("undeclared variable");
	}
	else {
		temp = allocate_var(found_symbol);
		int ivalue = stoi(value);
		gen_const(ivalue,temp);
	}
}

/*
* variable allocation in register or memory
*/
reg_label allocate_var(symbol *var){
	var->allocation = 0;
	int i = 1; // reg A - free

	while(registers[i].taken){
		i++;
	}

	registers[i].taken = true;
	var->curr_reg = registers[i].label;

	return var->curr_reg;
}

/*
*  constant value generation
*/
void gen_const(int value, reg_label acc){
	int curr = 1;
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
  cerr << "error: " << s << endl;
  exit(-1);
}
