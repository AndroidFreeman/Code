#include<stdio.h>
int fun(int n){
    static int a=1;
    a++;
    return a+n;
}
int main(){
    int n;
    // scanf("%d",&n);
    for(int i=1;i<9;i++){
        printf("%d\n",fun(i));
    }
    return 0;
}
