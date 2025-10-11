// #define col 5
#include<stdio.h>
#include<math.h>
int main(){
    int n,m,i,j,k;
    scanf("%d",&n);
    for(i=1;i<=n;i++){
        k=abs(i-(n+1)/2)
        for(j=1;j<=k;j++){
            printf(" ");
        }
        for(m=1;m<=n-2*k;m++){
            printf("*);
        }
        printf("\n");
    }
}
