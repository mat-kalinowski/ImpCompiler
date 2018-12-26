#ifndef DATA_H
#define DATA_H

#include <string>

using namespace std;

enum reg_label { A = 0, B = 1, C = 2, D = 3, E = 4, F = 5,G = 6,H = 7};
enum symbol_type{CONST,ID,ARR};
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
};

struct alloc {
  bool register;
  reg_label curr_reg;
  long long mem_adress;
  symbol_type type;

  alloc(reg_label curr_reg){
    this->reg_label = curr_reg;
    register = true;
  }
  
  alloc(long long mem_adress){
    this->mem_adress = mem_adress;
    register = false;
  }
}

struct reg_info{
  reg_label label;
  bool taken;
};

#endif
