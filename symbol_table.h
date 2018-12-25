#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <string>
#include <unordered_map>
#include <iostream>
#include "data.h"

using namespace std;

class symbol_table{
  public:
    void add_id(string name, symbol_type type, int size);
    void add_const(string name);
    symbol* get_var(string name);
    string reg_str(string name);
    string reg_str(symbol *var);

  private:
    unordered_map <string,symbol> table;

};

#endif
