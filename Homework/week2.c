#include<stdio.h>
int main(){
    Program1
    int number=0;
    printf("Enter the year:");
    scanf("%d", &number);
    if((number%4==0&&number%100!=0)||(number%400==0)){
        printf("Leap Year\n");
    }else{
        printf("Not Leap Year\n");
    }

    //Program2
    // printf("Enter a character:");
    // char ch;
    // ch=getchar();
    // if(ch>='a'&&ch<='z'){
    //     printf("Lowercase\n");
    //     printf("The anwser is:%c\n",('a'+(ch-'a'+6)%26));
    // }else if(ch>='A'&&ch<='Z'){
    //     printf("Uppercase\n");
    // }else{
    //     printf("Not a character\n");
    // }

    //Program3
    // int number;
    // printf("Enter a number:");
    // scanf("%d",&number);
    // if(number<0&&number!=-3){
    //     printf("The answer is:%d\n",number*number+number-6);
    // }else if(number>=0&&number<10&&number!=2&&number!=3){
    //     printf("The answer is:%d\n",number*number-5*number+6);
    // }else{
    //     printf("The answer is:%d\n",number*number-number-1);
    // }

    //Program4
    // int number[4];
    // for(int i=0;i<4;i++){
    //     printf("Enter number%d:",i+1);
    //     scanf("%d",&number[i]);
    // }
    // int *p_max=&number[0];
    // for(int i=0;i<4;i++){
    //     if(number[i]>*p_max){
    //         p_max=&number[i];
    //     }
    // }
    // printf("The max is:%d\n",*p_max);

    // Program5
    // int number[4];
    // int temp;
    // for(int i=0;i<4;i++){
    //     printf("Enter number%d:",i+1);
    //     scanf("%d",&number[i]);
    // }
    // for(int i=0;i<4;i++){
    //     for(int j=0;j<3-i;j++){
    //         if(number[j]>number[j+1]){
    //             temp=number[j];
    //             number[j]=number[j+1];
    //             number[j+1]=temp;
    //         }
    //     }
    // }
    // printf("The answer is:");
    // for(int i=0;i<4;i++){
    //     printf("%d ",number[i]);
    // }
    // printf("\n");

    //Program6
    // printf("Enter 2 number:");
    // double number1,number2,answer;
    // scanf("%lf %lf",&number1,&number2);
    // printf("Enter the oprator:");
    // char ch;
    // getchar();
    // ch=getchar();
    // switch(ch){
    //     case '+':
    //         answer=number1+number2;
    //         break;
    //     case '-':
    //         answer=number1-number2;
    //         break;
    //     case '/':
    //         answer=number1/number2;
    //         break;
    //     case '*':
    //         answer=number1*number2;
    //         break;
    // }
    // printf("The answer is:%lf",answer);

    //Program6_New
    // int a,b;
    // char op;
    // scanf("%d%c%d",&a,&op,&b);
    // switch(op){
    //     case '+':
    //         printf("%d%c%d=%d\n",a,op,b,a+b);
    //         break;
    //     case '-':
    //         printf("%d%c%d=%d\n",a,op,b,a-b);
    //         break;
    //     case '*':
    //         printf("%d%c%d=%d\n",a,op,b,a*b);
    //         break;
    //     case '/':
    //         printf("%d%c%d=%d\n",a,op,b,a/b);
    //         break;
    // }

    //Program7
    // int year, month, day;
    // int total_days = 0;
    // int is_leap = 0;
    // int days_in_month[13] = {0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    // printf("y m d:");
    // if (scanf("%d/%d/%d", &year, &month, &day) != 3) {
    //     printf("Error\n");
    //     return 1;
    // }
    // if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
    //     is_leap = 1;
    //     days_in_month[2] = 29;
    // }
    // if (month < 1 || month > 12) {
    //     printf("Error\n");
    //     return 1;
    // }
    // if (day < 1 || day > days_in_month[month]) {
    //     printf("Error\n");
    //     return 1;
    // }
    // for (int i = 1; i < month; i++) {
    //     total_days += days_in_month[i];
    // }
    // total_days += day;
    // printf("Result: %d \n", total_days);
}
