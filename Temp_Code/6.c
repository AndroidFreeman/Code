#include<stdio.h>
int main(){
    int number[]={1,2,3,4,5};
    int sum=0;
    for(int i=0;i<5;i++){
        sum+=number[i];
    }
    int ave=sum/5;
    printf("%d %d\n",sum,ave);
}
