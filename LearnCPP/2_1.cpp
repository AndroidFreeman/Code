#include<iostream>
extern int count;
void write_extern(void){
    std::cout<<count<<std::endl;
}
