#include<stdio.h>
int main(){

    //Program1
    int a,b,c;
    scanf("%d%d%d",&a,&b,&c);
    int*p1=&a,*p2=&b,*p3=&c;
    int*pmax=p1,*pmin=p1;
    if(*p2>*pmax)pmax=p2;
    if(*p3>*pmax)pmax=p3;
    if(*p2<*pmin)pmin=p2;
    if(*p3<*pmin)pmin=p3;
    printf("Max=%d Min=%d\n",*pmax,*pmin);

    //Program2
    const int N=5;
    int tmp[N];
    int total=0;
    for(int i=0;i<N;i++){
        scanf("%d",&tmp[i]);
        int*p=&tmp[i];
        total+=*p;
    }
    int ave=total/N;
    printf("%d\n",ave);

    //Program3
    const int O=5;
    int tmp3[O];
    int total_product=1;
    for(int i=0;i<O;i++){
        scanf("%d",&tmp3[i]);
        int*p=&tmp3[i];
        total_product*=*p;
    }
    printf("%d\n",total_product);

    //Program4
    int Q;
    scanf("%d",&Q);
    int tmpp[Q];
    int*p;
    int temp;
    for(p=tmpp;p<tmpp+Q;p++){
        scanf("%d",p);
    }
    int*p_max=tmpp;
    for(p=tmpp+1;p<tmpp+Q;p++){
        if(*p>*p_max){
            p_max=p;
        }
    }
    temp=*tmpp;
    *tmpp=*p_max;
    *p_max=temp;
    int*p_min=tmpp;
    for(p=tmpp+1;p<tmpp+Q;p++){
        if(*p<*p_min){
            p_min=p;
        }
    }
    int*p_last=tmpp+Q-1;
    temp=*p_last;
    *p_last=*p_min;
    *p_min=temp;
    for(p=tmpp;p<tmpp+Q;p++){
        printf("%d ",*p);
    }
    printf("\n");

    //Program5
    const int T_N=10;
    int input[T_N];
    for(int i=0;i<T_N;i++){
        scanf("%d",&input[i]);
    }
    int*p_start=input;
    int*p_end=input+T_N-1;
    int temp_5;
    while(p_start<p_end){
        temp_5=*p_start;
        *p_start=*p_end;
        *p_end=temp_5;
        p_start++;
        p_end--;
    }
    for(int i=0;i<T_N;i++){
        printf("%d ",input[i]);
    }
    printf("\n");

    //Program6
    const int SIZE=5;
    int arr_a[SIZE];
    int arr_b[SIZE];
    for(int i=0;i<SIZE;i++)scanf("%d",&arr_a[i]);
    for(int i=0;i<SIZE;i++)scanf("%d",&arr_b[i]);
    int*pa=arr_a;
    int*pb=arr_b;
    int temp_6;
    for(int i=0;i<SIZE;i++){
        temp_6=*pa;
        *pa=*pb;
        *pb=temp_6;
        pa++;
        pb++;
    }
    for(int i=0;i<SIZE;i++)printf("%d ",arr_a[i]);
    printf("\n");
    for(int i=0;i<SIZE;i++)printf("%d ",arr_b[i]);
    printf("\n");
}
