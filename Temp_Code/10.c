#include<stdio.h>
int fun(int n){
    static int a=1;
    a++;
    return a+n;
}
int main(){
    int n;
    // scanf("%d",&n);
    int (*q)[10];
    //创建一个指针q指向容量为10的一维数组
    int* p[10];
    //数组中每一个元素都是指针
    int (*p_fun)(int n)
    p_fun=function;
    for(int i=1;i<9;i++){
        printf("%d\n",fun(i));
    }
    return 0;
}


    int j=0;
    for(;s2[j]!='\0';j++);
    j--;
    int min;
    if(i>j){
        min=j;
    }else{
        min=i;
    }
    int bool=0;
