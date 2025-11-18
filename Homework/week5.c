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
    // const int N=5;
    // int tmp[N];
    // int total=0;
    // for(int i=0;i<N;i++){
    //     scanf("%d",&tmp[i]);
    //     int *p=&tmp[i];
    //     total+=*p;
    // }
    // int ave=total/N;
    // printf("%d",ave);

    //Program3
    const int O=5;
    int tmp[O];
    int total=1;
    for(int i=0;i<O;i++){
        scanf("%d",&tmp[i]);
        int *p=&tmp[i];
        total=total*(*p);
    }
    printf("%d",total);

    //Program4
    int Q;
    scanf("%d",&Q);
    int tmpp[Q];
    for(int i=0;i<Q;i++){
        scanf("%d",&tmpp[i]);
    }
    int* p_max = &tmpp[0];
    int* p_min = &tmpp[0];
    int* p;
    for (p = &tmpp[1]; p < &tmpp[Q]; p++) {
        if (*p > *p_max) {
            p_max = p;
        }
        if (*p < *p_min) {
            p_min = p;
        }
    }

    int temp = tmpp[0];
    temp = *p_last;
    *p_last = *p_min;
    *p_min = temp;

    for (int i = 0; i < Q; i++) {
        printf("%d ", tmpp[i]);
    }

    //Program5
}
