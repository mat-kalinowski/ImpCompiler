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
	void assign_value(symbol* name, string value);
	void assign_expr(symbol *name, expression *expr);
	void gen_const(int value, reg_label acc);
	reg_label allocate_var(symbol *var);
	void push_command(string command);

	symbol_table table;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false},{G,false},{H,false}};
	long long int mem_pointer = 0;
%}

%union{
	int ival;
	char* sval;
	expression *expr;
	symbol *smb;
}
%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN EQ
%token ADD SUB MOD MUL DIV
%token LB RB
%token <sval> PIDENTIFIER
%token <sval> NUM

%type <expr> expression;
%type <smb> identifier;
%type <smb> value;

%%

program: DECLARE declarations IN commands END {
	push_command("HALT");

  for(int i =0; i < output_code.size(); i++){
		cout << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { table.add_id((string) $2, ID,1); } |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM { table.add_id((string) $2, ARR,$6-$4); } |
;

commands: commands command |
 					command
;

command: identifier ASN expression SEM {assign_expr($1,$3); }
;

command: READ identifier SEM {}
;

command: WRITE identifier SEM {push_command("PUT " + table.reg_str($2));}
;

expression: value {$$ = new expression($1);} |
 						value ADD value {$$ = new expression($1,ADD,$3);}|
						value SUB value {$$ = new expression($1,SUB,$3);}|
						value MUL value {$$ = new expression($1,MUL,$3);}|
						value DIV value {$$ = new expression($1,DIV,$3);}|
						value MOD value {$$ = new expression($1,MOD,$3);}
;

value: NUM {table.add_const((string) $1); $$ = table.get_var((string)$1);} |
			 identifier
;

identifier: PIDENTIFIER { $$ = table.get_var((string)$1);}|
						PIDENTIFIER LB PIDENTIFIER RB { $$ = table.get_var((string)$1);}|
						PIDENTIFIER LB NUM RB { $$ = table.get_var((string)$1);}
;

%%

void assign_expr(symbol *name, expression *expr){
	symbol *val1 = expr->val1;
	symbol *val2 = expr->val2;
	int op = expr->op;

	if(op == -1){
		if(val1->type == CONST){
			assign_value(name, val1->value);
		}
		else if(val1->type == ID){
			if(name->allocation == 0){				// register
				push_command("COPY " + table.reg_str(name) + " " + table.reg_str(val1));
			}
			else if(name->allocation == -1){	// uninitialized
				allocate_var(name);
				push_command("COPY " + table.reg_str(name) +" " + table.reg_str(val1));
			}
			else if(name->allocation == 1){		// memory

			}
		}
		else if(val1->type == ARR){
			
		}
	}

}

void assign_value(symbol* found_symbol, string value){
	reg_label temp;

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

	while(registers[i].taken && i < registers.size()){
		i++;
	}

	if(i == registers.size()){
		var->mem_adress = mem_pointer;
		mem_pointer += var->size;
	}
	else{
			registers[i].taken = true;
			var->curr_reg = registers[i].label;
	}

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
