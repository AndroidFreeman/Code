#include<string.h>
#include<stdio.h>
//Program1
struct date{
    int yy,mm,dd;
}Date;
//Program2

//Program3
struct date{
    int month;
    int day;
    int year;
};
struct stu{
    int num;
    char sex,name[20];
    float ave,score[4];
    struct date birthday;
    float score[4];
    float ave;
};
void Input(struct stu* a){
    scanf("%d",&a.num);
    scanf("%c %s",&a.sex,&a.score);
    scanf("%lf %lf",&a.ave,&a.score);
    scanf("%d %d %d",&a->birthday.year,&a->birthday.month,&a->birthday.day);
    scanf("%lf",&a.score);
    scanf("%lf",&a.ave);
}
void Output(struct stu* a){
    printf("%d",&a.num);
    printf("%c %s",&a.sex,&a.score);
    printf("%lf %lf",&a.ave,&a.score);
    printf("%d %d %d",&a->birthday.year,&a->birthday.month,&a->birthday.day);
    printf("%lf",&a.score);
    printf("%lf",&a.ave);
}
void Inputarray(struct stu a[],int n){
    for(int i=0;i<n;i++){
        scanf("%d",&a[i].num);
        scanf("%c %s",&a[i].sex,&a[i].score);
        scanf("%lf %lf",&a[i].ave,&a[i].score);
        scanf("%d %d %d",&a[i]->birthday.year,&a[i]->birthday.month,&a[i]->birthday.day);
        scanf("%lf",&a[i].score);
        scanf("%lf",&a[i].ave);
    }
}
void Outputarray(struct stu a[],int n){
    for(int i=0;i<n;i++){
        printf("%d",&a[i].num);
        printf("%c %s",&a[i].sex,&a[i].score);
        printf("%lf %lf",&a[i].ave,&a[i].score);
        printf("%d %d %d",&a[i]->birthday.year,&a[i]->birthday.month,&a[i]->birthday.day);
        printf("%lf",&a[i].score);
        printf("%lf",&a[i].ave);
    }
}
void Searchname(struct stu a[],int n,char ch[]) {
    int found=0;
    for(int i=0;i<n;i++){
        if(strcmp(ch,a[i].name)==0){
            printf("\n查找成功,在第%d位:\n",i);
            Output(&a[i]);
            found = 1;
        }
    }
    if(!found){
        printf("404 Not Found\n");
    }
}
void Sortname(){

}
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
