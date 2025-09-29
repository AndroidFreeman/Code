#include<stdio.h>
int main(){
    //Program1
    // printf("Enter a number:");
    // int number;
    // scanf("%d",&number);
    // double sum=0.0;
    // double s=2.0;
    // double m=1.0;
    // double temp=0.0;
    // for(int i=1;i<=number;i++){
    //     sum=sum+s/m;
    //     temp=s;
    //     s=s+m;
    //     m=temp;
    // }
    // printf("Answer is:%lf\n",sum);

    //Program2
    int number,sum,temp;
    printf("Enter a number:");
    scanf("%d",&number);
    for(int i=1;i<=number;i++){
        for(int j=number;j==1;j--){
            temp=temp*j;
        }
        sum=sum+1/temp;
    }
    printf("The answer is:%d\n",sum);

    //Program7
    // int number=100;
    // int n1,n2,n3;
    // do{
    //     n1=number/100;
    //     n2=number/10%10;
    //     n3=number%10;
    //     if(n1*n1*n1+n2*n2*n2+n3*n3*n3==number){
    //         printf("Number=%d \n",number);
    //     }
    //     number++;
    // }while(number<=999);
}
