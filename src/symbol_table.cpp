#include "../headers/symbol_table.h"

/*
* adding variable to a symbol tabel
*/

void symbol_table::add_id(string name, int size){
	symbol new_symbol(size, ID);

	if(get_var(name) != NULL){
	  yyerror("redeclaration of variable");
		exit(-1);
	}

	table.insert({name,new_symbol});
}

void symbol_table::add_iterator(string name, int size){
	symbol new_symbol(size, ITER);

	if(get_var(name) != NULL){
	  yyerror("iterator name is already taken as variable");
	}

	table.insert({name,new_symbol});
}

void symbol_table::add_arr(string name, int size, int arr_beg){
	symbol new_symbol(size, ARR, arr_beg);

	if(get_var(name) != NULL){
		yyerror("redeclaration of variable");
	}
	if(size <= 0){
		yyerror("wrong size of an array");
	}

	new_symbol.allocation = 0;
	new_symbol.mem_adress = mem_pointer;
	mem_pointer += size;
	table.insert({name,new_symbol});
}

/*
* symbol tabel lookup for a variable
*/
symbol* symbol_table::get_var(string name){
	unordered_map<string,symbol>::iterator it = table.find(name);
	reg_label temp;

	if(it != table.end()){
		return &it->second;
	}

	return NULL;
}

/*
*returning register of a given symbol name as string
*/
string symbol_table::reg_str(string name){
	return (string)label_str[get_var(name)->curr_reg];
}

/*
*returning register of a given symbol as string
*/
string symbol_table::reg_str(symbol *var){
	return (string)label_str[var->curr_reg];
}

/*
*declarated variable validation
*/
void symbol_table::checkVar(string name, symbol_type var_type ){
	symbol* temp = get_var(name);
	if(!temp){
		yyerror("undeclared variable use");
	}
	if(temp->type == ARR && (var_type == ID || var_type == ITER)){
		yyerror("wrong array name context");
	}
	if((temp->type == ID || temp->type == ITER) && var_type == ARR){
		yyerror("wrong variable name context");
	}
}

/*
* expression variables validation
*/
void symbol_table::checkExpression(alloc* var1){
	if(var1->type != CONST){
		if(var1->allocation == -1){
			yyerror("uinitialized variable use in expression");
		}
	}
}

/*
* assignment to a variable validation
*/
void symbol_table::checkAssignment(string name){
	symbol* temp = get_var(name);
	if(!temp){
		yyerror("wrong assignment expression");
	}
	if(temp->type == ITER){
		yyerror("cannot change loop iterator");
	}
}

void symbol_table::remove(string name){
	table.erase(name);
}
