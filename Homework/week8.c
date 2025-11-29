#include<stdio.h>
//Program1
struct date{
    int yy,mm,dd;
}Date;
//Program2

//Program3
struct stu{
    int num;
    char sex,name[20];
    float ave,score[4];
    struct date birthday;
};

int main(){
    //Program1
    scanf("%d%d%d",&Date.yy,&Date.mm,&Date.dd);
    int days[13]={0,31,28,31,30,31,30,31,31,30,31,30,31};
    if((Date.yy%4==0&&Date.yy%100!=0)||Date.yy%400==0){
        days[2]=29;
    }
    int answer=0;
    for(int i=1;i<Date.mm;i++){
        answer+=days[i];
    }
    answer+=Date.dd;
    printf("%d",answer);
    return 0;

    //
}
