#include <stdio.h>

#define Switches ((volatile long *) 0x10000040)
#define RLEDs ((volatile long *) 0x10000000)
void slider()
{ 
   long Swval;
   unsigned long Sw4val;
   while (1)
   {
      Swval = *Switches;
      Sw4val = Swval & 0x01;
      if (Sw4val)
         return;
   }
}