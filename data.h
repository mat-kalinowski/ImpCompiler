#ifndef DATA_H
#define DATA_H

#include <string>

enum reg_label { A = 0, B = 1, C = 2, D = 3, E = 4, F = 5};
const char *label_str[]={ "A","B","C","D","E","F"};

struct symbol{
  int value;
  bool simple;
  bool initialized;
  reg_label curr_reg;

  symbol(bool simple){
    this->simple = simple;
  }
};

struct reg_info{
  reg_label label;
  bool taken;
};

#endif
