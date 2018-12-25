#ifndef DATA_H
#define DATA_H

#include <string>

using namespace std;

enum reg_label { A = 0, B = 1, C = 2, D = 3, E = 4, F = 5,G = 6,H = 7};
enum symbol_type{CONST, ID,ARR};
static const char *label_str[]={ "A","B","C","D","E","F","G","H"};

struct symbol{
  int size;
  int allocation;    // -1 ~ not placed , 0 ~ register, 1 ~ memory
  string value;
  symbol_type type;
  reg_label curr_reg;
  long long int mem_adress;

  symbol(int size, symbol_type type){
    this->size = size;
    allocation = -1;
    this->type = type;
  }
  symbol(string value){
    this->size =1;
    allocation = -1;
    this->type = CONST;
    this->value = value;
  }
};

struct expression{
  symbol *val1;
  int op;
  symbol *val2;

  expression(symbol *val1, int op, symbol *val2){
    this->val1 = val1;
    this->op = op;
    this->val2 = val2;
  }
  expression(symbol *val1){
    this->val1 = val1;
    this->op = -1;
    this->val2 = NULL;
  }
};

struct reg_info{
  reg_label label;
  bool taken;
};

#endif
