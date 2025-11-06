#include<stdio.h>
//Program2
int Fact(int n){
    if(n==0||n==1) return 1;
    return n*Fact(n-1);
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

int main(){
    //Program2
    int i,sum=0;
    scanf("%d",&n);
    for(i=1;i<=n;i++){
        sum+=Fact(i);
    }

    //Program3
    int n;
    scanf("%d",&n);
    double result=fun(n);
    printf("%lf\n",result);

    //Program4
    int j;
    scanf("%d",&j);
    double result=fun(j);
    printf("%d\n",result);
}
