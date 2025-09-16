#include<stdio.h>
int main(){
    // printf("Enter a 24-hour time:");
    // int hour,minute;
    // char time[]="AM";

    // scanf("%d:%d",&hour,&minute);
    // if(hour>12){
    //     hour=hour-12;
    //     char time1[]="PM";
    //     printf("Equicalent 12-hour time: %d:%d %s \n",hour,minute,time1);
    // }else{
    //     printf("Equicalent 12-hour time: %d:%d %s \n",hour,minute,time);
    // }
    // printf("Enter your wind:");
    // int ver;
    // scanf("%d",&ver);
    // if (ver<1){
    //     printf("Calm");
    // }else if(ver<4){
    //     printf("Light air");
    // }else if(ver<28){
    //     printf("Breeze");
    // }else if(ver<48){
    //     printf("Gale");
    // }else if(ver<64){
    //     printf("Storm");
    // }else{
    //     printf("Hurricane");
    // }

    float income;
    printf("Enter your income:");
    scanf("%f",&income);
    if(income<=750){
        printf("%f",income*0.01);
    }else if(income<=2250){
        printf("%f",7.50+0.02*(income-750))
    }
}
