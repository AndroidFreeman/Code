#include<stdio.h>
int main(){
    int m,n;
    int min,max;
    int t1,t2;
    int a,b;
    a=1;
    int i;
    scanf("%d%d",&m,&n);
    if(m>n){
        min=n;
        max=m;
    }else{
        min=m;
        max=n;
    }
    for(i=min;i>0;i--){
        if(min%i==0&&max%i==0){
            a=i;
            break;
        }
    }
    b=min*max/a;
    printf("%d,%d\n",a,b);
}
