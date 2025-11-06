#include<stdio.h>

int Fact(int n){
    if(n==0||n==1) return 1;
    return n*Fact(n-1);
}

int Fib(int n){
    if(n==1||n==2){
        return 1;
    }
    return Fib(n-1)+Fib(n-2);
}



int main(){
    for(int i=1;i<=9;i++){
        printf("%d\n",Fact(i));
    }
    for(int i=1;i<=9;i++){
        printf("%d\n",Fib(i));
    }
}
