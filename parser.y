%{
	#include "data.h"
	#include "symbol_table.h"
	#include "parser_dec.h"

	#include <iostream>
	#include <unordered_map>
	#include <string>
	#include <vector>

	using namespace std;

  extern int yylex();
	extern int yyparse();
	extern FILE *yyin;

	void yyerror(const char *s);
	void genConst(int value, reg_label acc);
	void allocateVar(alloc *var);
	void allocIde(alloc* var);
	void pushCommand(string command);
	alloc* genArrConst(string ide, string index);
	alloc* genVar(string ide);
	alloc* genArrVar(string arr, string ide);
	void assignSingleExpression(alloc* var, alloc* expr);
	void assignExpression(alloc* var, alloc* expr);
	alloc* addExpression(alloc* var1, alloc* var2);
	alloc* subExpression(alloc* var1, alloc* var2);
	alloc* mulExpression(alloc* var1, alloc* var2);
	alloc* divExpression(alloc* var1, alloc* var2);
	alloc* modExpression(alloc* var1, alloc* var2);
	void movRegToMem(reg_label, alloc* mem);
	void movMemToReg(alloc* mem, reg_label reg);
	void movMemToMem(alloc* mem_to, alloc* mem_from);
	void addValToMem(alloc* mem_var);
	void write(alloc *value);
	void genConst(long long int value, reg_label reg);
	void pushCommand(string command);

	symbol_table table;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false},{G,false},{H,false}};
	long long int mem_pointer = 0;
	bool singleExpression = false;
%}

%union{
	long long ival;
	char* sval;
	alloc *allocated;
}

%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN EQ
%token ADD SUB MOD MUL DIV
%token LB RB
%token <sval> PIDENTIFIER
%token <sval> NUM

%type <allocated> expression;
%type <allocated> identifier;
%type <allocated> value;

%%

program: DECLARE declarations IN commands END {
	pushCommand("HALT");

  for(int i =0; i < output_code.size(); i++){
		cout << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { table.add_id((string) $2,1);} |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM {table.add_arr((string) $2,stoi($6)-stoi($4)+1,stoi($4));} |
;

commands: commands command |
 					command
;

command: identifier ASN expression SEM {
	allocIde($1);
	if(singleExpression){
		assignSingleExpression($1,$3);
		singleExpression = false;
	}
	else{
		assignExpression($1,$3);
	}
}
;

command: READ identifier SEM {}
;

command: WRITE identifier SEM {write($2);}
;

expression: value {$$ = $1; singleExpression = true;}|                  /*  zawartość zawsze w rejestrze B   */
 						value ADD value {$$ = addExpression($1,$3); }|
						value SUB value {$$ = subExpression($1,$3); }|
						value MUL value {$$ = mulExpression($1,$3); }|
						value DIV value {$$ = divExpression($1,$3); }|
						value MOD value {$$ = modExpression($1,$3); }
;

value: NUM { $$ = new alloc($1,CONST);} |
			 identifier
;

identifier: PIDENTIFIER {  table.checkVar((string)$1); $$ = genVar($1);}|
						PIDENTIFIER LB PIDENTIFIER RB {	table.checkVar((string)$1); $$ = genArrVar($1,$3);}|
						PIDENTIFIER LB NUM RB { table.checkVar((string)$1); $$ = genArrConst($1,$3);}
;

%%

alloc* genVar(string ide){
	symbol* temp = table.get_var(ide);
	alloc* ret;

	ret = new alloc(ide,ID);
	ret->allocation = temp->allocation;

	if(ret->allocation == 1){
		ret->curr_reg = temp->curr_reg;
	}
	else if(ret->allocation == 0){
		ret->mem_adress = temp->mem_adress;
	}

	return ret;
}

alloc* genArrConst(string ide, string index){
	symbol* temp = table.get_var(ide);
	int i_ind = stoi(index);
	alloc* ret = new alloc(ide,temp->mem_adress + i_ind-temp->arr_beg,ARR);

	return ret;
}

alloc* genArrVar(string arr, string ide){
	symbol* temp = table.get_var(arr);
	alloc* ret = new alloc(arr,temp->mem_adress,ARR,ide);

	return ret;
}

void assignSingleExpression(alloc* var, alloc* expr){														//przypisanie zmiennej do pojedynczej zmiennej
	if(var->allocation){
		if(expr->allocation){																							//obydwie zmienne zaalokowane w rejestrach
			pushCommand("COPY " + (string)label_str[var->curr_reg] + " " + (string)label_str[expr->curr_reg]);
		}
		else{
			if(expr->type == CONST){
				genConst(stoi(expr->name),var->curr_reg);
			}
			else{
				movMemToReg(expr, var->curr_reg);
			}
		}
	}
	else{
		if(expr->allocation){																							//obydwie zmienne zaalokowane w rejestrach
			movRegToMem(expr->curr_reg, var);
		}
		else{
			if(expr->type == CONST){
				genConst(stoi(expr->name),B);
				movRegToMem(B, var);
			}
			else{
				movMemToMem(var, expr );
			}
		}
	}
}

void assignExpression(alloc* var, alloc* expr){																	// expression jest zawsze w rejestrze B
	if(var->allocation){
		pushCommand("COPY " + (string)label_str[var->curr_reg] + " " + (string)label_str[expr->curr_reg]);
	}
	else{
		cerr << "var adress:" <<var->mem_adress << endl;
		movRegToMem(expr->curr_reg, var);
	}
}

void allocIde(alloc* var){
	if(var->allocation == -1){
		allocateVar(var);
	}
}

void write(alloc *value){
	if(value->allocation){
		pushCommand("PUT " + (string)label_str[value->curr_reg]);
	}
	else{
		movMemToReg(value, B);
		pushCommand("PUT " + (string)label_str[B]);
	}
}

void allocateVar(alloc *var){																						/* alokacja rejestru zmiennych - 3 pierwsze reg wolne */
	int i = 3;
	symbol* temp = table.get_var(var->name);

	while(registers[i].taken && i < registers.size()){
		i++;
	}

	if(i == registers.size()){
		var->allocation = 0;
		var->mem_adress = mem_pointer;
		temp->mem_adress = var->mem_adress;
		temp->allocation = 0;
		mem_pointer += temp->size;
	}

	else{
			var->allocation = 1;
			registers[i].taken = true;
			var->curr_reg = registers[i].label;
			temp->curr_reg = var->curr_reg;
	}
	temp->allocation = var->allocation;
}

void genConst(long long int value, reg_label reg){																												/* generating constant in given register */
	int curr = 1;
	string reg_str = label_str[reg];

	output_code.push_back("SUB "+ reg_str + " " + reg_str);

	if(value != 0){
		output_code.push_back("INC "+ reg_str);

		while(curr*2 < value){
			output_code.push_back("ADD "+ reg_str + " " + reg_str);
			curr *= 2;
		}
		if(curr != value){
			while(curr != value){
				output_code.push_back("INC "+ reg_str);
				curr++;
			}
		}
	}
}

void movRegToMem(reg_label reg,alloc* mem_var){
	long long int mem = mem_var->mem_adress;

	genConst(mem,A);
	addValToMem(mem_var);
	pushCommand("STORE " + (string)label_str[reg]);
}

void movMemToReg(alloc* mem_var, reg_label reg){
	long long int mem = mem_var->mem_adress;

	genConst(mem,A);
	addValToMem(mem_var);
	pushCommand("LOAD " + (string)label_str[reg]);
}

void movMemToMem(alloc* mem_to, alloc* mem_from){
	long long int mem1 = mem_to->mem_adress;
	long long int mem2 = mem_from->mem_adress;

	genConst(mem1,A);
	addValToMem(mem_from);
	pushCommand("LOAD " + (string)label_str[B]);
	genConst(mem2,A);
	addValToMem(mem_to);
	pushCommand("STORE " + (string)label_str[B]);
}

void pushCommand(string command){
	output_code.push_back(command);
}

void addValToMem(alloc* mem_var){										// wygenerowanie wartości indeksu w reg C
	if(mem_var->type == ARR){
		if(mem_var->var_ind){
			symbol* val = table.get_var(mem_var->ind_name);					// can be NULL - possible segfault
			symbol* mem_val = table.get_var(mem_var->name);

			if(val->allocation){
				pushCommand("ADD A "+(string)label_str[val->curr_reg]);
			}
			else{
				pushCommand("COPY C A");
				genConst(val->mem_adress,A);
				pushCommand("LOAD A");
				pushCommand("ADD A C");
			}
			genConst(mem_val->arr_beg,C);
			pushCommand("SUB A C");
		}
	}
}

alloc* addExpression(alloc* var1, alloc* var2){
	if(var1->type == CONST && var2->type == CONST){
		long long temp = stoi(var1->name);
		long long temp2 = stoi(var2->name);
		genConst(temp+temp2,B);
	}
	else if(var1->allocation && var2->allocation){
		pushCommand("COPY B " + (string)label_str[var1->curr_reg]);
		pushCommand("ADD B " +(string)label_str[var2->curr_reg]);
	}
	else if(var1->allocation && !var2->allocation){
		movMemToReg(var2,B);
		pushCommand("ADD B " + (string)label_str[var1->curr_reg]);
	}
	else if(!var1->allocation && var2->allocation){
		movMemToReg(var1,B);
		pushCommand("ADD B " + (string)label_str[var2->curr_reg]);
	}
	return new alloc("",B,CONST);
}

alloc* subExpression(alloc* var1, alloc* var2){}

alloc* mulExpression(alloc* var1, alloc* var2){}

alloc* divExpression(alloc* var1, alloc* var2){}

alloc* modExpression(alloc* var1, alloc* var2){}

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
