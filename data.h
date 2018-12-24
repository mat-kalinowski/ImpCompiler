#ifndef DATA_H
#define DATA_H

#include <string>

enum reg_label { A = 0, B = 1, C = 2, D = 3, E = 4, F = 5,G = 6,H = 7};
enum symbol_type{CONST, ID,ARR};
static const char *label_str[]={ "A","B","C","D","E","F","G","H"};

struct symbol{
  int size;
  bool simple;
  symbol_type type;
  int allocation;    // -1 ~ uninitialized , 0 ~ register, 1 ~ memory
  reg_label curr_reg;
  long long int mem_adress;

  symbol(bool simple, int size, symbol_type type){
    this->simple = simple;
    this->size = size;
    allocation = -1;
    this->type = type;
  }
};

struct reg_info{
  reg_label label;
  bool taken;
};

#endif
