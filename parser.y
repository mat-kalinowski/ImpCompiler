%{
	#include "data.h"
	#include "symbol_table.h"
	#include "parser_dec.h"

	#include <iostream>
	#include <fstream>
	#include <string>
	#include <vector>
	#include <algorithm>

	using namespace std;

  extern int yylex();
	extern int yylineno;
	extern int yyparse();
	extern FILE *yyin;

	void yyerror(const char *s);

	void allocateVar(alloc *var);
	void pushCommand(string command);
	void assignSingleExpression(alloc* var, alloc* expr);
	void assignExpression(alloc* var, alloc* expr);
	alloc* genArrConst(string ide, string index);
	alloc* genVar(string ide);
	alloc* genArrVar(string arr, string ide);
	alloc* addExpression(alloc* var1, alloc* var2);
	alloc* subExpression(alloc* var1, alloc* var2);
	alloc* mulExpression(alloc* var1, alloc* var2);
	alloc* divExpression(alloc* var1, alloc* var2);
	alloc* modExpression(alloc* var1, alloc* var2);
	void movRegToMem(reg_label, alloc* mem);
	void movMemToReg(alloc* mem, reg_label reg);
	void movMemToMem(alloc* mem_to, alloc* mem_from);
	void movExprToReg(alloc* var1, alloc* var2);
	void addValToMem(alloc* mem_var);
	void movValToIterator(alloc* var1, alloc* var2);

	void write(alloc* value);
	void read(alloc* value);
	void genConst(long long value, reg_label reg);
	void pushCommand(string command);

	block* generateEQ(alloc* var1, alloc* var2);
	block* generateNEQ(alloc* var1, alloc* var2);
	block* generateLE(alloc* var1, alloc* var2);
	block* generateEQL(alloc* var1, alloc* var2);

	void resolveIfJump(block* cond);
	void resolveWhileJump(block* cond);
	void resolveDoWhileJump(int beg,block* cond);

	block* setIncLoop(string it_name, alloc* val1, alloc* val2);
	void setIncJump(block* for_beg, string it_name);
	block* setDecLoop(string it_name, alloc* val1, alloc* val2);
	void setDecJump(block* for_beg, string it_name);

	symbol_table table;
	ofstream out_file;

	vector<vector<jump*>> jumpStack;
	vector<string> output_code;
	vector<reg_info> registers = {{A,false},{B,false},{C, false},{D, false},{E,false},{F,false},{G,false},{H,false}};

	long long int mem_pointer = 0;
	long long int codeOffset = 0;
	bool singleExpression = false;
%}

%union{
	long long ival;
	char* sval;
	alloc *allocated;
	block* blc;
}

%token READ WRITE
%token DECLARE IN END
%token SEM COL ASN
%token ADD SUB MOD MUL DIV
%token EQ NEQ LE GE EQL EQG
%token LB RB
%token WHILE ENDDO ENDWHILE
%token FROM TO DOWNTO ENDFOR
%token IF THEN ELSE ENDIF

%token <ival> DO
%token <blc> FOR
%token <sval> PIDENTIFIER
%token <sval> NUM

%type <blc> condition;         /* miejsce początku warunku i następnej instrukcji po warunku */
%type <allocated> expression;
%type <allocated> identifier;
%type <allocated> value;

%%

program: DECLARE declarations IN commands END {
	pushCommand("HALT");

  for(int i =0; i < output_code.size(); i++){
		out_file << output_code[i] << endl;
	}
}
;

declarations: declarations PIDENTIFIER SEM { table.add_id((string) $2,1);} |
 							declarations PIDENTIFIER LB NUM COL NUM RB SEM {table.add_arr((string) $2,stol($6)-stol($4)+1,stol($4));} |
;

commands: commands command |
 					command
;

command: identifier ASN expression SEM {
	allocateVar($1);
	table.checkAssignment($1->name);
	if(singleExpression){
		assignSingleExpression($1,$3);
		singleExpression = false;
	}
	else{
		assignExpression($1,$3);
	}
}
;

command: READ identifier SEM { table.checkAssignment($2->name); read($2);} |
				 IF condition THEN commands { pushCommand("JUMP "); $<ival>1 = codeOffset-1; resolveIfJump($2); }
				 ELSE commands ENDIF { output_code[$<ival>1] += to_string(codeOffset); }|
				 IF condition THEN commands ENDIF { resolveIfJump($2); }|
				 WHILE condition DO commands ENDWHILE { resolveWhileJump($2); }|
				 DO { $1 = codeOffset;} commands WHILE condition ENDDO { resolveDoWhileJump($1,$5); } |
				 FOR PIDENTIFIER FROM value TO value DO { $1 = setIncLoop($2,$4,$6); } commands ENDFOR { setIncJump($1,$2); } |
				 FOR PIDENTIFIER FROM value DOWNTO value DO { $1 = setDecLoop($2,$4,$6); } commands ENDFOR { setDecJump($1,$2); } |
 				 WRITE value SEM { table.checkExpression($2); write($2);} |
;

expression: value {table.checkExpression($1);$$ = $1; singleExpression = true;}|                  /*  zawartość zawsze w rejestrze B   */
 						value ADD value { table.checkExpression($1); $$ = addExpression($1,$3); table.checkExpression($3); }|
						value SUB value { table.checkExpression($1); $$ = subExpression($1,$3); table.checkExpression($3); }|
						value MUL value { table.checkExpression($1); $$ = mulExpression($1,$3); table.checkExpression($3); }|
						value DIV value { table.checkExpression($1); $$ = divExpression($1,$3); table.checkExpression($3); }|
						value MOD value { table.checkExpression($1); $$ = modExpression($1,$3); table.checkExpression($3); }
;

condition: value EQ value  { $$ = generateEQ($1,$3); }|
					 value NEQ value { $$ = generateNEQ($1,$3); }|
					 value LE value  { $$ = generateLE($1,$3); }|
					 value GE value  { $$ = generateLE($3,$1); }|
					 value EQL value { $$ = generateEQL($1,$3); }|
					 value EQG value { $$ = generateEQL($3,$1); }
;

value: NUM { $$ = new alloc($1,CONST);} |
			 identifier
;

identifier: PIDENTIFIER {
							table.checkVar((string)$1, ID);
							$$ = genVar($1);}|
						PIDENTIFIER LB PIDENTIFIER RB {
							table.checkVar((string)$1, ARR);
							$$ = genArrVar($1,$3);}|
						PIDENTIFIER LB NUM RB {
							table.checkVar((string)$1, ARR);
							$$ = genArrConst($1,$3);}
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
	int i_ind = stol(index);
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
				genConst(stol(expr->name),var->curr_reg);
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
				genConst(stol(expr->name),B);
				movRegToMem(B, var);
			}
			else{
				movMemToMem(var, expr);
			}
		}
	}
}

void assignExpression(alloc* var, alloc* expr){																	// expression jest zawsze w rejestrze B
	if(var->allocation){
		pushCommand("COPY " + (string)label_str[var->curr_reg] + " " + (string)label_str[expr->curr_reg]);
	}
	else{
		movRegToMem(expr->curr_reg, var);
	}
}

void write(alloc *value){
	if(value->type == CONST){
		genConst(stol(value->name), B);
		pushCommand("PUT " + (string)label_str[B]);
	}
	else if(value->allocation){
		pushCommand("PUT " + (string)label_str[value->curr_reg]);
	}
	else{
		movMemToReg(value, B);
		pushCommand("PUT " + (string)label_str[B]);
	}
}

void read(alloc* value){
	allocateVar(value);
	if(value->allocation){
		pushCommand("GET " + (string)label_str[value->curr_reg]);
	}
	else{
		pushCommand("GET " + (string)label_str[B]);
		movRegToMem(B,value);
	}
}

void allocateVar(alloc *var){																						/* alokacja rejestru zmiennych - 3 pierwsze reg wolne */
	if(var->allocation == -1){
		int i = 5;
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
}

void genConst(long long value, reg_label reg){																												/* generating constant in given register */
	long long curr = 1;
	string reg_str = label_str[reg];
	vector<char> op;

	pushCommand("SUB "+ reg_str + " " + reg_str);

	while(value > 0){
		if(value % 2){
			op.push_back('i');
			value --;
		}
		else{
			op.push_back('s');
			value /= 2;
		}
	}
	reverse(begin(op), end(op));

	for(int i =0; i < op.size(); i++){
		if(op[i] == 'i'){
			pushCommand("INC " + reg_str);
		}
		else{
			pushCommand("ADD " + reg_str + " " + reg_str);
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

	genConst(mem2,A);
	addValToMem(mem_from);
	pushCommand("LOAD " + (string)label_str[B]);
	genConst(mem1,A);
	addValToMem(mem_to);
	pushCommand("STORE " + (string)label_str[B]);
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

void movExprToReg(alloc* var1, alloc* var2, reg_label reg1, reg_label reg2){

	if(var1->type == CONST){
		genConst(stol(var1->name),reg1);
  }
 	else if(!var1->allocation){
		movMemToReg(var1, reg1);
 	}
	else if(var1->allocation){
		pushCommand("COPY " + (string)label_str[reg1] + " " + (string)label_str[var1->curr_reg]);
	}

	if(var2->type == CONST){
		genConst(stol(var2->name),reg2);
	}
	else if(!var2->allocation){
		movMemToReg(var2,reg2);
	}
	else if(var2->allocation){
		pushCommand("COPY " + (string)label_str[reg2] + " " + (string)label_str[var2->curr_reg]);
	}
}

void movValToIterator(alloc* var1, alloc* var2, int exVal){
	if(var1->allocation == 1){																						// i placed in mem or reg  1.) i = val1
		if(var2->type == CONST){
			genConst(stol(var2->name)+exVal,var1->curr_reg);
		}
		else if(var2->allocation ==1){
			pushCommand("COPY " + (string)label_str[var1->curr_reg] + (string)label_str[var2->curr_reg]);
			if(exVal != 0){
				pushCommand("INC " + (string)label_str[var1->curr_reg]);
			}
		}
		else if(!var2->allocation){
			movMemToReg(var2,var1->curr_reg);
			if(exVal != 0){
				pushCommand("INC "+ (string)label_str[var1->curr_reg]);
			}
		}
	}
	else if(!var1->allocation){
		if(var2->type == CONST){
			genConst(stol(var2->name)+exVal,B);
			movRegToMem(B,var1);
		}
		else if(var2->allocation ==1){
			if(exVal != 0){
				pushCommand("COPY E " + (string)label_str[var2->curr_reg]);
				pushCommand("INC E");
				movRegToMem(E,var1);
			}
			else{
				movRegToMem(var2->curr_reg,var1);
			}
		}
		else if(!var2->allocation){
			if(exVal!=0){
				movMemToReg(var2,E);
				pushCommand("INC E");
				movRegToMem(E,var1);
			}
			else{
				movMemToMem(var1,var2);
			}
		}
	}
}

alloc* addExpression(alloc* var1, alloc* var2){
	if(var1->type == CONST && var2->type == CONST){
		long long temp = stol(var1->name);
		long long temp2 = stol(var2->name);
		genConst(temp+temp2,B);
	}
	else if(var2->type == CONST){
		if(var1->allocation){
			genConst(stol(var2->name),B);
			pushCommand("ADD B " + (string)label_str[var1->curr_reg]);
		}
		else{
			genConst(stol(var2->name),B);
			movMemToReg(var1,C);
			pushCommand("ADD B C");
		}
	}
	else if(var1->type == CONST){
		if(var2->allocation){
			genConst(stol(var1->name),B);
			pushCommand("ADD B " + (string)label_str[var2->curr_reg]);
		}
		else{
			genConst(stol(var1->name),B);
			movMemToReg(var2,C);
			pushCommand("ADD B C");
		}
	}
	else{
		if(var1->allocation && var2->allocation){
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
		else if(!var1->allocation && !var2->allocation){
			movMemToReg(var1,B);
			movMemToReg(var2,C);
			pushCommand("ADD B C");
		}
	}

	return new alloc("",B,CONST);
}

alloc* subExpression(alloc* var1, alloc* var2){
	if(var1->type == CONST && var2->type == CONST){
		long long temp = stol(var1->name);
		long long temp2 = stol(var2->name);
		genConst(temp-temp2,B);
	}
	else if(var2->type == CONST){
		if(var1->allocation){
			genConst(stol(var2->name),C);
			pushCommand("COPY B " + (string)label_str[var1->curr_reg]);
			pushCommand("SUB B C");
		}
		else{
			movMemToReg(var1,B);
			genConst(stol(var2->name),C);
			pushCommand("SUB B C");
		}
	}
	else if(var1->type == CONST){
		if(var2->allocation){
			genConst(stol(var1->name),B);
			pushCommand("SUB B " + (string)label_str[var2->curr_reg]);
		}
		else{
			movMemToReg(var2,C);
			genConst(stol(var1->name),B);
			pushCommand("SUB B C");
		}
	}
	else{
		if(var1->allocation && var2->allocation){
			pushCommand("COPY B " + (string)label_str[var1->curr_reg]);
			pushCommand("SUB B " +(string)label_str[var2->curr_reg]);
		}
		else if(var1->allocation && !var2->allocation){
			movMemToReg(var2,C);
			pushCommand("COPY B "+ (string)label_str[var1->curr_reg]);
			pushCommand("SUB B C");
		}
		else if(!var1->allocation && var2->allocation){
			movMemToReg(var1,B);
			pushCommand("SUB B " + (string)label_str[var2->curr_reg]);
		}
		else if(!var1->allocation && !var2->allocation){
			movMemToReg(var1,B);
			movMemToReg(var2,C);
			pushCommand("SUB B C");
		}
	}

	return new alloc("",B,CONST);
}

alloc* mulExpression(alloc* var1, alloc* var2){
	reg_label mul_reg;

	if(var1->type == CONST && var2->type == CONST){
		long long temp = stol(var1->name);
		long long temp2 = stol(var2->name);
		genConst(temp*temp2,B);
	}
	else{

		movExprToReg(var1,var2,B,C);

		pushCommand("SUB A A");
		long long loop_beg = output_code.size();
		long long odd_cond = loop_beg + 3;
		long long skip_cond = loop_beg + 4;

		pushCommand("JZERO B " + to_string(loop_beg+7));
		pushCommand("JODD B " + to_string(odd_cond));
		pushCommand("JUMP " + to_string(skip_cond));
		pushCommand("ADD A C");
		pushCommand("ADD C C");
		pushCommand("HALF B");
		pushCommand("JUMP " + to_string(loop_beg));
		pushCommand("COPY B A");
	}
	return new alloc("",B,CONST);
}

alloc* divExpression(alloc* var1, alloc* var2){						// divide reg B by reg C --->   B - DIVIDENT , C - DIVISOR
	if(var2->type == CONST && stol(var2->name) == 0){
		pushCommand("SUB E E");
	}
	if(var1->type == CONST && var2->type == CONST){
		long long temp = stol(var1->name);
		long long temp2 = stol(var2->name);
		genConst(temp/temp2,E);
	}
	else{

		movExprToReg(var1,var2,B,C);

		pushCommand("SUB E E"); // e - result
		pushCommand("JZERO C " + to_string(output_code.size()+21));
		pushCommand("SUB D D");
		pushCommand("INC D");  // d - mul

		pushCommand("COPY A C");
		pushCommand("INC A");
		pushCommand("SUB A B");
		pushCommand("JZERO A " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() + 4));
		pushCommand("ADD C C");
		pushCommand("ADD D D");
		pushCommand("JUMP " + to_string(output_code.size() - 7));

		pushCommand("COPY A C");
		pushCommand("SUB A B");
		pushCommand("JZERO A " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() + 3));
		pushCommand("SUB B C");
		pushCommand("ADD E D");
		pushCommand("HALF C");
		pushCommand("HALF D");
		pushCommand("JZERO D " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() - 9));
	}

	return new alloc("",E,CONST);
}

alloc* modExpression(alloc* var1, alloc* var2){
	if(var2->type == CONST && stol(var2->name) == 0){
		pushCommand("SUB E E");
	}
	else if(var1->type == CONST && var2->type == CONST){
		long long temp = stol(var1->name);
		long long temp2 = stol(var2->name);
		genConst(temp/temp2,B);
	}
	else{
		movExprToReg(var1,var2,B,C);

		pushCommand("SUB E E"); // e - result
		pushCommand("JZERO C " + to_string(output_code.size() + 22));
		pushCommand("SUB D D");
		pushCommand("INC D");  // d - mul

		pushCommand("COPY A C");
		pushCommand("INC A");
		pushCommand("SUB A B");
		pushCommand("JZERO A " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() + 4));
		pushCommand("ADD C C");
		pushCommand("ADD D D");
		pushCommand("JUMP " + to_string(output_code.size() - 7));

		pushCommand("COPY A C");
		pushCommand("SUB A B");
		pushCommand("JZERO A " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() + 3));
		pushCommand("SUB B C");
		pushCommand("ADD E D");
		pushCommand("HALF C");
		pushCommand("HALF D");
		pushCommand("JZERO D " + to_string(output_code.size() + 2));
		pushCommand("JUMP " + to_string(output_code.size() - 9));
		pushCommand("COPY E B");
	}
	return new alloc("",E,CONST);
}

block* generateEQ(alloc* var1, alloc* var2){ 				// var1 == var2 ?  A == B ?
	long long curr_index = output_code.size();
	vector <jump*> curr_jumps;

	if(var1->type == CONST && var2->type == CONST){
		long long num1 = stol(var1->name);
		long long num2 = stol(var2->name);

		(num1 == num2) ? pushCommand("SUB C C") : pushCommand("INC C");
	}
	else{
		movExprToReg(var1,var2, E, B);

		pushCommand("COPY C E");
		pushCommand("COPY D B");
		pushCommand("SUB C B");
		pushCommand("SUB D E");
		pushCommand("ADD C D");
	}
	pushCommand("JZERO C ");  // + to_string(output_code.size()+2);
	curr_jumps.push_back(new jump(output_code.size()-1, BLOCK));
	pushCommand("JUMP ");
	curr_jumps.push_back(new jump(output_code.size()-1, OUT));

	jumpStack.push_back(curr_jumps);

	return new block(curr_index, output_code.size());
}

block* generateNEQ(alloc* var1, alloc* var2){
	long long curr_index = output_code.size();
	vector <jump*> curr_jumps;

	if(var1->type == CONST && var2->type == CONST){
		long long num1 = stol(var1->name);
		long long num2 = stol(var2->name);

		(num1 != num2) ? pushCommand("INC C") : pushCommand("SUB C C");
	}
	else{
		movExprToReg(var1,var2,E,B);

		pushCommand("COPY C E");
		pushCommand("COPY D B");
		pushCommand("SUB C B");
		pushCommand("SUB D E");
		pushCommand("ADD C D");
	}

	pushCommand("JZERO C ");
	curr_jumps.push_back(new jump(codeOffset-1,OUT));

	jumpStack.push_back(curr_jumps);

	return new block(curr_index, codeOffset);
}

block* generateLE(alloc* var1, alloc* var2){
	long long curr_index = output_code.size();
	vector <jump*> curr_jumps;

	if(var1->type == CONST && var2->type == CONST){
		long long num1 = stol(var1->name);
		long long num2 = stol(var2->name);

		(num1 < num2) ?  pushCommand("INC B") : pushCommand("SUB B B");
	}
	else{
		movExprToReg(var1, var2,E,B);

		pushCommand("SUB B E");
	}

	pushCommand("JZERO B");
	curr_jumps.push_back(new jump(codeOffset - 1,OUT));
	jumpStack.push_back(curr_jumps);

	return new block(curr_index, codeOffset);
}

block* generateEQL(alloc* var1, alloc* var2){
	long long curr_index = output_code.size();
	vector <jump*> curr_jumps;

	if(var1->type == CONST && var2->type == CONST){
		long long num1 = stol(var1->name);
		long long num2 = stol(var2->name);

		(num1 <= num2) ?  pushCommand("SUB E E") : pushCommand("INC E");
	}
	else{
		movExprToReg(var1, var2,E,B);
		pushCommand("SUB E B");
	}
	pushCommand("JZERO E");			// jump curr + 2
	pushCommand("JUMP");				// jump end

	curr_jumps.push_back(new jump(codeOffset - 2,BLOCK));
	curr_jumps.push_back(new jump(codeOffset - 1,OUT));
	jumpStack.push_back(curr_jumps);

	return new block(curr_index, codeOffset);
}

void pushCommand(string command){
	output_code.push_back(command);
	codeOffset++;
}

void resolveIfJump(block* cond){
	vector<jump*> curr_jumps = jumpStack[jumpStack.size()-1];

	int num = curr_jumps.size();

	for(int i = 0; i < num; i++){
		jump* temp = curr_jumps[i];

		if(temp->type == BLOCK){
			output_code[temp->index] += to_string(cond->end_block);
		}

		else if(temp->type == OUT){
			output_code[temp->index] += to_string(codeOffset);
		}
	}
	jumpStack.pop_back();
}

void resolveWhileJump(block* cond){
	vector<jump*> curr_jumps = jumpStack[jumpStack.size()-1];
	pushCommand("JUMP " + to_string(cond->beg_block));

	int num = curr_jumps.size();

	for(int i =0; i < num; i ++){
		jump* temp = curr_jumps[i];

		if(temp->type == BLOCK){
			output_code[temp->index] += to_string(cond->end_block);
		}
		else if(temp->type == OUT){
			output_code[temp->index] += to_string(codeOffset);
		}
	}

	jumpStack.pop_back();
}

void resolveDoWhileJump(int beg,block* cond){
	vector<jump*> curr_jumps = jumpStack[jumpStack.size()-1];
	bool block_jump = false;
	jump* temp;

	for(int i =0; i < curr_jumps.size(); i ++){
		temp = curr_jumps[i];

		if(temp->type == BLOCK){
			block_jump = true;
		}
	}

	if(!block_jump){
		pushCommand("JUMP");
		curr_jumps.push_back(new jump(codeOffset-1,BLOCK));
	}

	for(int i =0; i < curr_jumps.size(); i ++){
		temp = curr_jumps[i];

		if(temp->type == BLOCK){
			output_code[temp->index] += to_string(beg);
		}
		else if(temp->type == OUT){
			output_code[temp->index] += to_string(codeOffset);
		}
	}
}

block* setIncLoop(string var, alloc* val1, alloc* val2){ 										// returning place to jump at the bottom
	long long loop_ind;
	long long out_jump;

	table.add_iterator(var,1);
	alloc* var_info = genVar(var);
	allocateVar(var_info);
	alloc* bound = new alloc("",mem_pointer,ID);
	mem_pointer +=1;

	movValToIterator(bound, val2, 0);
	movValToIterator(var_info, val1,0);

	loop_ind = codeOffset;

	movExprToReg(var_info,bound,B,C);
	pushCommand("SUB B C");
	pushCommand("JZERO B " + to_string(codeOffset+2));
	out_jump = codeOffset;
	pushCommand("JUMP ");

	return new block(loop_ind, out_jump);
}

void setIncJump(block* for_beg, string it_name){
	alloc* var_info = genVar(it_name);

	if(var_info->allocation ){
		pushCommand("INC " + (string)label_str[var_info->curr_reg]);
		pushCommand("COPY B " + (string)label_str[var_info->curr_reg]);
	}
	else if(!var_info->allocation){
		movMemToReg(var_info,B);
		pushCommand("INC B");
		movRegToMem(B,var_info);
	}
	pushCommand("JUMP "+ to_string(for_beg->beg_block));
	output_code[for_beg->end_block] += to_string(codeOffset);
	table.remove(it_name);
}

block* setDecLoop(string var, alloc* val1, alloc* val2){ 										// returning place to jump at the bottom
	long long loop_ind;
	long long out_jump;

	table.add_iterator(var,1);
	alloc* var_info = genVar(var);
	allocateVar(var_info);
	alloc* bound = new alloc("",mem_pointer,ID);
	mem_pointer +=1;

	movValToIterator(bound, val2, 0);
	movValToIterator(var_info, val1,1);

	loop_ind = codeOffset;

	movExprToReg(var_info,bound,B,C);
	pushCommand("COPY D B");
	pushCommand("SUB D C");
	out_jump = codeOffset;
	pushCommand("JZERO D ");

	pushCommand("DEC B");

	if(var_info->allocation){
		pushCommand("COPY " + string(label_str[var_info->curr_reg]) + " B");
	}
	else if(!var_info->allocation){
		movRegToMem(B,var_info);
	}

	return new block(loop_ind, out_jump);
}

void setDecJump(block* for_beg,string it_name){
	pushCommand("JUMP "+ to_string(for_beg->beg_block));
	output_code[for_beg->end_block] += to_string(codeOffset);
	table.remove(it_name);
}

int main (int argc, char **argv){
	if(argc > 0){
			FILE *file_in = fopen(argv[1], "r");
			out_file.open(argv[2]);

			if (!file_in ) {
			 cerr << "cannot open file " << argv[1] << endl;
			 return -1;
		 	}
			yyin = file_in;
	}

	else{
		yyin = stdin;
	}

	yyparse();
}

void yyerror(const char *s) {
  cerr << "\033[1;31mERROR: \033[0m" << s << " in line " << yylineno << endl;
  exit(-1);
}
