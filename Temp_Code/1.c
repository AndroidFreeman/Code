#include<stdio.h>
int main(){
    int number[20];
    int j;
    scanf("%d",&number[1]);
    number[0]=number[1]=1;
    for(int i=0;i<=17;i++){
        number[i+2]=number[i+1]+number[i];
    }
    for(j=0;j<=9;j++){
        printf("%d\t",number[j]);
    }
    printf("\n");
    for(j=10;j<=19;j++){
        printf("%d\t",number[j]);
    }
    printf("\n");
}
