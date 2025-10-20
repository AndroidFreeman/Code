#include<stdio.h>
int main(){
    //Program1
    // double up=2;
    // double down=1;
    // double temp=0;
    // double sum=0;
    // int number;
    // scanf("%d",&number);
    // for(int i=0;i<number;i++){
    //     temp=up/down;
    //     sum+=temp;
    //     temp=down;
    //     down=up;
    //     up=up+temp;
    // }
    // printf("%lf\n",sum);

    //Program2
    // double sum=1.0;
    // int i=1;
    // double p=1.0;
    // double t=1.0;
    // while(t>=1e-6){
    //     sum+=t;
    //     i++;
    //     p=i*p;
    //     t=1.0/p;
    // }
    // printf("%lf\n",sum);

    //Program3

    //Program4
    // int score;
    // int ave;
    // int min=101;
    // int max=-1;
    // int i=0;
    // int temp=0;
    // scanf("%d",&score);
    // while(score!=-1){
    //     if(score>100){
    //         continue;
    //     }
    //     if(score>max){
    //         max=score;
    //     }
    //     if(score<min){
    //         min=score;
    //     }
    //     temp+=score;
    //     i++;
    //     scanf("%d",&score);
    // }
    // ave=temp/i;
    // printf("%d,%d,%d\n",max,min,ave);

    //Program5
    int m,n;
    int min,max;
    int t1,t2;
    int a,b;
    a=1;
    scanf("%d%d",&m,&n);
    if(m>n){
        min=n;
        max=m;
    }else{
        min=m;
        max=n;
    }
    for(int i=min;i>0;i--){
        if(min%i==0&&max%i==0){
            a=i;
            break;
        }
    }
    b=min*max/a;
    printf("%d,%d\n",a,b);
}
