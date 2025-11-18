#include<stdio.h>
int main(){
    //Program1
    const int M=3;
    int temp[M];
    int* p;
    for(int i=0;i<3;i++){
        scanf("%d",temp[i]);
    }
    for(int i=0;i<3;i++){
        if(temp[i]>temp[i+1]){
            *p=temp[i];
            temp[i]=temp[i+1];
            temp[i+1]=*p
        }else{
            continue;
        }
    }
    for(int i=0;i<3;i++){
        printf("%d",temp[i]);
    }
}
