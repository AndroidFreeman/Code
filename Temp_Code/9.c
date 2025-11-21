#include<stdio.h>
//Program1
double Fun1(one,two){
    double answer;
    double big,small;
    if(one>two){
        big=one;
        small=two;
    }else{
        big=two;
        small=one;
    }
    int fact;
    
}
//Program2
int Fun2(int n){
    if(n==0||n==1) return 1;
    return n*Fun2(n-1);
}
//Program3
double Fun3(int n){
    double result=0.0;
    int fm=0;
    for(int i=1;i<=n;i++){
        fm+=i;
        result+=1.0/fm;
    }
    return result;
}
//Program4
int Fun4(int a,int b){
    int ones,tens,huns,thos,res;
    ones=a%10;tens=b/10;
    huns=a/10;thos=b%10;
    res=ones+tens*10+huns*100+thos*1000;
    return res;
}
//Program5
void Fun5_1(int* arr,int n){
    for(int i=0;i<n;i++){
        scanf("%d",arr+i);
    }
}
void Fun5_2(int* arr,int n){
    int temp;
    int *pMin=arr;
    for(int i=1;i<n;i++){
        if(*(arr+i)<*pMin){
            pMin=arr+i;
        }
    }
    temp=*arr;
    *arr=*pMin;
    *pMin=temp;
    int *pMax=arr;
    for(int i=1;i<n;i++){
        if(*(arr+i)>*pMax){
            pMax=arr+i;
        }
    }
    int *pLast=arr+n-1;
    temp=*pLast;
    *pLast=*pMax;
    *pMax=temp;
}
void Fun5_3(int *arr,int n){
    for(int i=0;i<n;i++){
        printf("%d ",*(arr+i));
    }
    printf("\n");
}
//Program6
void Fun6(int M,int* answer_num,int input_arr[]){
    *answer_num=0;
    for(int i=2;i<M;i++){
        int isPrime=1;
        for(int j=2;j<i;j++){
            if(i%j==0){
                isPrime=0;
                break;
            }
        }
        if(isPrime==0){
            input_arr[*answer_num]=i;
            *answer_num=*answer_num+1;
        }
    }
}

int main(){
    //Program1
    int input_one,input_two;
    scanf("%d %d",&input_one,&input_two);
    double answer=Fun1(input_one,input_two);
    printf("%lf",answer);
    //Program2
    int n,sum=0;
    scanf("%d",&n);
    for(int i=1;i<=n;i++){
        sum+=Fun2(i);
    }
    printf("%d\n",sum);
    //Program3
    int n3;
    scanf("%d",&n3);
    double result3=Fun3(n3);
    printf("%lf\n",result3);
    //Program4
    int a,b;
    scanf("%d%d",&a,&b);
    int result4=Fun4(a,b);
    printf("%d\n",result4);
    //Program5
    const int N=10;
    int arr[N];
    Fun5_1(arr,N);
    Fun5_2(arr,N);
    Fun5_3(arr,N);
    //Program6
    const int M=100;
    int answer_num=0;
    int input_arr[M];
    Fun6(M,&answer_num,input_arr);
    for(int i=0;i<answer_num;i++){
        printf("%d ",input_arr[i]);
    }
    printf("\n");
    return 0;
}
