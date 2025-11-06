#include<stdio.h>
int main(){
    int input[10];
    int height=0;
    int height_max=0;
    int apple=0;
    for(int i=0;i<10;i++){
        scanf("%d",&input[i]);
        if(input[i]<100||input[i]>200){
            return 1;
        }
    }
    scanf("%d",&height);
    if(height<100||height>120){
        return 1;
    }
    height_max=height+30;
    for(int i=0;i<10;i++){
        if(input[i]<=height_max){
            apple+=1;
        }
    }
    printf("%d",apple);
}
