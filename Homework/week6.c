#include<stdio.h>
//Program1
double Fun1(int input_1,int input_2){
    double upper=Fun1T(input_1);
    double down1=Fun1T(input_2);
    double down2=Fun1T(input_1-input_2);
    double answer=(upper/down1/down2);
    return answer;
}
double Fun1T(int number){
    int answer=1;
    for(int i=number;i>0;i--){
        answer=answer*i;
        Fun1T(i);
    }
    return answer;
}
//Program2
int Fun2(int n){
    if(n==0||n==1) return 1;
    return n*Fun2(n-1);
}

//Program3
double Fun3(int n){
    double result=0.0;
    double fm=0.0;
    for(int i=1;i<=n;i++){
        fm+=1;
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
    int *pMin = arr;
    for (int i = 1; i < n; i++) {
        if (*(arr + i) < *pMin) {
            pMin = arr + i;
        }
    }
    temp = *arr;
    *arr = *pMin;
    *pMin = temp;
    int *pMax = arr;
    for (int i = 1; i < n; i++) {
        if (*(arr + i) > *pMax) {
            pMax = arr + i;
        }
    }
    int *pLast = arr + n - 1;
    temp = *pLast;
    *pLast = *pMax;
    *pMax = temp;
}

void Fun5_3(int *arr,int n){
    for(int i=0;i<n;i++){
        printf("%d",*(arr+1));
    }
    printf("\n");
}

//Program6
void Fun6(int M,int* answer_num,int input_arr[]){
    *answer_num=0;
    int isPrime=1;
    for(int i=2;i<M;i++){
        for(int j=2;j<=i;j++){
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
    int input_1,input_2;
    int bigger,smaller;
    scanf("%d %d",&input_1,&input_2);
    if(input_1>input_2){
        smaller=input_2;
        bigger=input_1;
    }else{
        smaller=input_1;
        bigger=input_2;
    }
    double ans_1=Fun1(bigger,smaller);
    printf("%lf",ans_1);

    //Program2
    int i,n,sum=0;
    scanf("%d",&n);
    for(i=1;i<=n;i++){
        sum+=Fun2(i);
    }

    //Program3
    int nn;
    scanf("%d",&nn);
    double result3=Fun3(nn);
    printf("%lf\n",result3);

    //Program4
    int j;
    scanf("%d",&j);
    double result4=Fun4(j);
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
    for(int i=0;i<M;i++){
        printf("%d",input_arr[i]);
    }
}
