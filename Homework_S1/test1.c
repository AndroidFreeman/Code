#include<stdio.h>
//Program3
int strlen(char* str){
    int i=0;
    while(str[i]!='\0'){
        i++;
    }
    return i;
}

int main(){
    //Program1
    int a1=1;
    int a2=1;
    printf("%d %d ",a1,a2);
    for(int i=1;i<=18;i++){
        sum=sum+a2;
        a1=a2;
        a2=sum;
        printf("%d",sum);
    }
    printf("\n");

    //Program2
    int yy,mm,dd;
    int isR=0;
    int day=0;
    scanf("%d%d%d",&yy,&mm,&dd);
    if((yy%4==0&&yy%100!=0)||(yy%400==0)){
        isR=1;
    }
    int arr1[]={31,28,31,30,31,30,31,31,30,31,30,31};
    int arr2[]={31,29,31,30,31,30,31,31,30,31,30,31};
    if(isR){
        for(int i=0;i<mm-1;i++){
            day+=arr2[i];
        }
        day+=dd;
    }else{
        for(int i=0;i<mm-1;i++){
            day+=arr1[i];
        }
        day+=dd;
    }
    printf("%d",day);

    //Program3
    char ch[2005];
    scanf("%s",ch);
    int index=strlen(ch);
    printf("%d",index);

    //Program4
    int arr[3][4];
    int max=-1001;
    for(int i=0;i<3;i++){
        for(int j=0;j<4;j++){
            scanf("%d",&arr[i][j]);
            if(arr[i][j]>max){
                max=arr[i][j];
            }
        }
    }
    printf("%d",max);
}


