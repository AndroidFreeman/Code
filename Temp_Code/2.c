#include<stdio.h>
int main(){
    int number[10];
    int max=number[0];
    for(int i=0;i<=9;i++){
        scanf("%d",&number[i]);
    }
    for(int j=0;j<=9;j++){
        if(number[j]>max){
            max=number[j];
        }
    }
    printf("The max number:%d\n",max);
}
