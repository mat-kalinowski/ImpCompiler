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
	void pushCommand(string command);

	symbol_table table;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false},{G,false},{H,false}};
	long long int mem_pointer = 0;
%}

%union{
	long long ival;
	char* sval;
	symbol *smb;
	alloc *alloc;
}
%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN EQ
%token ADD SUB MOD MUL DIV
%token LB RB
%token <sval> PIDENTIFIER
%token <ival> NUM

%type <alloc> expression;
%type <alloc> identifier;
%type <alloc> value;

%%

program: DECLARE declarations IN commands END {
	push_command("HALT");

  for(int i =0; i < output_code.size(); i++){
		cout << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { table.add_id((string) $2, ID,1);} |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM { table.add_id((string) $2, ARR,$6-$4); mem_pointer += $6 - $4;} |
;

commands: commands command |
 					command
;

command: identifier ASN expression SEM {assignExpression($1,$3);}
;

command: READ identifier SEM {}
;

command: WRITE identifier SEM {write($2);}
;

expression: value {$$ = $1;} |                  /*  zawartość zawsze w rejestrze B   */
 						value ADD value {$$ = addExpresion($1,$3);}|
						value SUB value {$$ = subExpression($1,$3);}|
						value MUL value {$$ = mulExpression($1,$3);}|
						value DIV value {$$ = divExpression($1,$3);}|
						value MOD value {$$ = modExpression($1,$3);}
;

value: NUM { $$ = genConst($1);} |									/* stała wygenerowana w rejestrze A  */
			 identifier
;

identifier: PIDENTIFIER { $$ = genVar($1);}|
						PIDENTIFIER LB PIDENTIFIER RB { $$ = genArrVar($1,$3);}|
						PIDENTIFIER LB NUM RB { $$ = genArrConst($1,$3);}
;

%%

alloc* genVar(string ide){
	symbol* temp = table.get_var(ide);
	alloc* ret;

	if(temp->allocation){
		alloc = new ret(temp->curr_reg);
	}
	else{
		alloc = new ret(temp->mem_adress);
	}

	return ret;
}

alloc* genArrConst(string ide, long long index){
	symbol* temp = table.get_var(arr);
	alloc* ret = new ret(temp->mem_adress + index);

	return ret;
}

alloc* genArrVar(string arr, string ide){
	symbol* temp = table.get_var(arr);
	/* ???? */
}

void assignExpression(alloc* var, alloc* expr){
	if(var->register){
		if(expr->register){
			pushCommand("COPY " + var->curr_reg + " " + expr->curr_reg);
		}
		else{
		}
	}
	else{
		if(expr->register){

		}
		else{

		}
	}
}

void write(alloc *value){
	if(value->register){
		pushCommand("PUT " + value->curr_reg);
	}
	else{
		pushCommand("HEHE");
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
reg_label allocate_reg(symbol *var){																						/* alokacja rejestru zmiennych - 3 pierwsze reg wolne */
	int i = 3;

	while(registers[i].taken && i < registers.size()){
		i++;
	}

	if(i == registers.size()){
		var->allocation = 0;
		var->mem_adress = mem_pointer;
		mem_pointer += var->size;
	}
	else{
			var->allocation = 1;
			registers[i].taken = true;
			var->curr_reg = registers[i].label;
	}

	return var->curr_reg;
}

/*
*  constant value generation
*/
void genConst(int value){																												/* generating constant in register B */
	int curr = 1;
	string reg_str = label_str[C];

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

void pushCommand(string command){
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
