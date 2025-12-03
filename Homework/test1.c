#include<stdio.h>
//Program3
int strlen(char* str){
    
}

int main(){
    //Program1
    printf("1 1 ");
    for(int i=1;i<=20;i++){
        int a1=1;
        int a2=1;
        int sum=1;
        sum=sum+a2;
        int temp=sum;
        a1=a2;
        a2=temp;
        printf("%d",sum);
    }

    //Program2
    int yy,mm,dd;
    int isR=0;
    int day=0;
    scanf("%d%d%d",&yy,&mm,&dd);
    if((yy%4==0&&yy%100!=0)||(yy%400==0)){
        isR=1;
    }
    int arr1[]={31,28,31,30,31,30,31,31,30,31,30,31};
    int arr2[]={31,29,31,30,31,30,31,31,30,31,30,31};
    if(isR){
        for(int i=0;i<mm-1;i++){
            day+=arr2[i];
        }
        day+=dd;
    }else{
        for(int i=0;i<mm-1;i++){
            day+=arr1[i];
        }
        day+=dd;
    }
    printf("%d",day);

    //Program3

}


