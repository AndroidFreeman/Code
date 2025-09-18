#include<stdio.h>
int main(){
    int sum=0;
    int i;
    printf("Enter a number:");
    scanf("%d",&i);
    do{
        sum=sum+1;
        i++;
    }while(i<=10);
    printf("sum=%d",sum);
}
