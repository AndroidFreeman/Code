#include<stdio.h>
#include<stdbool.h>
#include<ctype.h>
#define N 10
#define MSG_LEN 255
#define DAYS 30
#define HOURS 24
#define NOW 8
#include<stdlib.h>
#include<time.h>
// const int segments[10][7] = {
//     {1, 1, 1, 1, 1, 1, 0},  // 0
//     {0, 1, 1, 0, 0, 0, 0},  // 1
//     {1, 1, 0, 1, 1, 0, 1},  // 2
//     {1, 1, 1, 1, 0, 0, 1},  // 3
//     {0, 1, 1, 0, 0, 1, 1},  // 4
//     {1, 0, 1, 1, 0, 1, 1},  // 5
//     {1, 0, 1, 1, 1, 1, 1},  // 6
//     {1, 1, 1, 0, 0, 0, 0},  // 7
//     {1, 1, 1, 1, 1, 1, 1},  // 8
//     {1, 1, 1, 1, 0, 1, 1}   // 9
// };


int main(){
    // int weekend[7]={[0]=true,[6]=true};
    // for(int i=0;i<7;i++){
    //     printf("%d\n",weekend[i]);
    // }

    // double temperature_readings[DAYS][HOURS];
    // srand(time(0));
    // for(int day=0;day<DAYS;day++){
    //     for(int hour=0;hour<HOURS;hour++){
    //         temperature_readings[day][hour]=(rand()%350)/10;
    //     }
    // }
    // double total_temp=0.0;
    // for(int day=0;day<DAYS;day++){
    //     for(int hour=0;hour<HOURS;hour++){
    //         total_temp+=temperature_readings[day][hour];
    //     }
    // }
    // double average_temp=total_temp/(DAYS*HOURS);
    // printf("The month we save %d number\n",DAYS*HOURS);
    // printf("Total:%f\n",total_temp);
    // printf("Average:%f\n",average_temp);

    // char checker_board[NOW][NOW];
    // for(int i=0;i<NOW;i++){
    //     for(int j=0;j<NOW;j++){
    //         if((i+j)%2==0){
    //             checker_board[i][j]='B';
    //         }else{
    //             checker_board[i][j]='R';
    //         }
    //     }
    // }
    // for(int i=0;i<NOW;i++){
    //     for(int j=0;j<NOW;j++){
    //         printf("%c ",checker_board[i][j]);
    //     }
    //     printf("\n");
    // }

    // int count[10]={0};
    // int digit;
    // long n;
    // bool found=false;
    // printf("Enter a number");
    // scanf("%ld",&n);
    // long zero=n;
    // while(n>0){
    //     digit=n%10;
    //     count[digit]++;
    //     n/=10;
    // }
    // if(zero==0){
    //     count[0]++;
    // }
    // for(int i=0;i<10;i++){
    //     if(count[i]>1){
    //         found=true;
    //         printf(" %d",i);
    //     }
    // }
    // if(found){
    //     printf("\n");
    // }else{
    //     printf("NO repeated digit\n");
    // }
    // return 0;

//     char message[MSG_LEN];
//     char ch;
//     int i = 0;
//     printf("Enter message: ");
//     while ((ch = getchar()) != '\n' && i < MSG_LEN - 1) {
//         message[i] = ch;
//         i++;
//     }
//     message[i] = '\0';
//     printf("In B1FF-speak: ");
//     for (i = 0; message[i] != '\0'; i++) {
//         ch = toupper(message[i]);
//         switch (ch) {
//             case 'A':
//                 putchar('4');
//                 break;
//             case 'B':
//                 putchar('8');
//                 break;
//             case 'E':
//                 putchar('3');
//                 break;
//             case 'I':
//                 putchar('1');
//                 break;
//             case 'O':
//                 putchar('0');
//                 break;
//             case 'S':
//                 putchar('5');
//                 break;
//             default:
//                 putchar(ch);
//                 break;
//         }
//     }
//     for (i = 0; i < 10; i++) {
//         putchar('!');
//     }
//     printf("\n");

    int array[5][5];
    for (int i=1;i=<5;i++){
        printf("Enter row %d:",i);
        scanf("%d %d %d %d %d",array[i][1],
            array[i][2],array[i][3],array[i][4],array[i][1])
    }
}
