#include<stdio.h>
int main(){
    //Program1
    int n=20;
    int arr[n];
    arr[0]=1;
    arr[1]=1;
    for(int i=2;i<n;i++){
        arr[i]=arr[i-1]+arr[i-2];
    }
    for(int i=0;i<n;i++){
        printf("%d",arr[i]);
    }

    //Program2
    int yy,mm,dd;
    scanf("%d%d%d",&yy,&mm,&dd);
    
}


