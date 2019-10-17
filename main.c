#include <stdio.h>

void setValue(int * const num) {
  // *num = 42;
  int j = 32;
  num = &j;
}

int main(void) {
  int i = 0;
  int *iptr = &i;
  setValue(iptr);
  printf("value = %d\n", *iptr);
  return 0;
}
  
