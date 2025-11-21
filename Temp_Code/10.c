#include<stdio.h>
int fun(int n){
    int a=1;
    a++;
    return a+3;
}
int main(){
    int n;
    scanf("%d",&n);
    for(int i=1;i<3;i++){
        printf("%d\n",fun(i));
    }
    return 0;
}
