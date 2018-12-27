#ifndef DATA_H
#define DATA_H

#include <string>

using namespace std;

enum reg_label { A = 0, B = 1, C = 2, D = 3, E = 4, F = 5,G = 6,H = 7};
enum symbol_type{CONST,ID,ARR};
static const char *label_str[]={ "A","B","C","D","E","F","G","H"};

struct symbol{
  int size;
  int allocation;    // -1 ~ not placed , 0 ~ memory, 1 ~ register
  reg_label curr_reg;
  long long int mem_adress;
  symbol_type type;
  int arr_beg;

  symbol(int size, symbol_type type){
    this->size = size;
    this->allocation = -1;
    this->type = type;
  }
  symbol(int size, symbol_type type, int arr_beg){
    this->size = size;
    this->allocation = -1;
    this->type = type;
    this->arr_beg = arr_beg;
  }
};

struct alloc {
  string name;
  int allocation;      // -1 ~ not placed , 0 ~ memory, 1 ~ register
  reg_label curr_reg;
  long long int mem_adress;
  bool var_ind;
  string ind_name;
  symbol_type type;

  alloc(string name, reg_label curr_reg, symbol_type type){
    this->name = name;
    this->curr_reg = curr_reg;
    this->type = type;
    this->var_ind = false;
    this->allocation = 1;
  }

  alloc(string name, long long mem_adress, symbol_type type){
    this->name = name;
    this->mem_adress = mem_adress;
    this->type = type;
    this->var_ind = false;
    this->allocation = 0;
  }
  alloc(string name, symbol_type type){
    this->name = name;
    this->type = type;
    this->var_ind = false;
    this->allocation = 0;
  }
  alloc(string name, long long mem_adress, symbol_type type, string ind_name){
    this->name = name;
    this->mem_adress = mem_adress;
    this->type = type;
    this->ind_name = ind_name;
    this->var_ind = true;
    this->allocation = 0;
  }
};

struct reg_info{
  reg_label label;
  bool taken;
};

#endif
