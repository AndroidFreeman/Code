#include<stdio.h>
int main(){
    printf("Enter a 24-hour time:");
    int hour,minute;
    char time[]="AM";

    scanf("%d:%d",&hour,&minute);
    if(hour>12){
        hour=hour-12;
        char time[]="PM";
        printf("Equicalent 12-hour time: %d:%d %s",hour,minute,time);
    }else{
        printf("Equicalent 12-hour time: %d:%d %s",hour,minute,time);
    }

}
