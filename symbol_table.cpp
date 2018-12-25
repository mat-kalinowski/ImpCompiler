#include "symbol_table.h"

/*
* adding variable to a symbol tabel
*/

void symbol_table::add_id(string name, symbol_type type, int size){
	symbol new_symbol(size, type);

	if(get_var(name) != NULL){
	  cerr<<"redeclaration of variable" << endl;
		exit(-1);
	}
	table.insert({name,new_symbol});
}

void symbol_table::add_const(string name){
	symbol new_symbol(name);
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
