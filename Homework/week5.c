#include<stdio.h>
int main(){
    //Program1
    // const int M=3;
    // int temp[M];
    // for(int i=0;i<M;i++){
    //     scanf("%d",&temp[i]);
    // }
    // for(int i=0;i<M-1;i++){
    //     int* p1=&temp[i];
    //     int* p2=&temp[i+1];
    //     if(*p1>*p2){
    //         int swap=*p1;
    //         *p1=*p2;
    //         *p2=swap;
    //     }
    // }
    // for(int i=0;i<3;i++){
    //     printf("%d ",temp[i]);
    // }
    // printf("\n");

    //Program2
    const int N=5;
    int tmp[N];
    int total;
    for(int i=0;i<N;i++){
        scanf("%d",&tmp[i]);
        int *p=tmp[N];
        total+=*p;
    }
    int ave=total/N;
    printf("%d",ave);
}
