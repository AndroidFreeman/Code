#include<stdio.h>
// #define M 4
// #define N 5
int main(){
    //Program1
    // int a[15], low, high, mid, search;
    // bool found = false;
    // printf("Enter a number:\n");
    // for (int i = 0; i < 15; i++) {
    //     scanf("%d", &a[i]);
    // }
    // printf("Enter search: ");
    // scanf("%d", &search);
    // low = 0;
    // high = 14;
    // while (low <= high) {
    //     mid = low + (high - low) / 2;
    //     if (search == a[mid]) {
    //         printf("Find it!, %d\n", mid + 1);
    //         found = true;
    //         break;
    //     } else if (search > a[mid]) {
    //         low = mid + 1;
    //     } else { // search < a[mid]
    //         high = mid - 1;
    //     }
    // }
    // if (!found) {
    //     printf("Doesn't exist.\n");
    // }

    //Program2
    // int a[M],b[N],c[M+N],i,j,k;
    // for(i=0;i<M;i++){
    //     scanf("%d",&a[i]);
    // }for(j=0;j<N;j++){
    //     scanf("%d",&b[j]);
    // }for(i=j=k=0;i<M&&j<N;){
    //     if(a[i]<=b[j]){
    //         c[k++]=a[i++];
    //     }else{
    //         c[k++]=b[j++];
    //     }
    // }
    // while(i<M){
    //     c[k++]=a[i++];
    // }
    // while(j<N){
    //     c[k++]=b[j++];
    // }
    // for(l=0;k<M+N;k++){
    //     printf("%d",c[k]);
    // }
    // printf("\n");

    //Program3
    // int class_number = 70;
    // int score[class_number];
    // long long count = 0;
    // double average;
    // int temp;
    // int low_score[class_number];
    // int actual_student_count = 0;
    // int low_score_count = 0;
    // printf("请输入学生成绩 (输入 -1 结束):\n");
    // for (int i = 0; i < class_number; i++) {
    //     scanf("%d", &temp);
    //     if (temp > 100) {
    //         printf("分数无效(>100)，已忽略。\n");
    //         continue;
    //     }
    //     if (temp == -1) {
    //         break;
    //     }
    //     score[actual_student_count] = temp;
    //     count = count + temp;
    //     actual_student_count++;
    // }
    // if (actual_student_count == 0) {
    //     printf("没有输入有效成绩。\n");
    //     return 0;
    // }
    // average = (double)count / actual_student_count;
    // for (int i = 0; i < actual_student_count; i++) {
    //     if (score[i] < average) {
    //         low_score[low_score_count] = score[i];
    //         low_score_count++;
    //     }
    // }
    // printf("\n--- 结果 ---\n");
    // printf("低于平均分的成绩有 %d 个:\n", low_score_count);
    // for (int i = 0; i < low_score_count; i++) {
    //     printf("%d ", low_score[i]);
    // }
    // printf("\n");
    // printf("平均分: %.2f\n", average);
    // printf("总分: %lld\n", count);
    // printf("有效学生人数: %d\n", actual_student_count);

    //Program4
    // int data[] = {5, 1, 4, 2, 8, 3, 7, 6};
    // int n = sizeof(data) / sizeof(data[0]);
    // int i, j;
    // int temp;
    // bool swapped;
    // printf("原始数组: ");
    // for (i = 0; i < n; i++) {
    //     printf("%d ", data[i]);
    // }
    // printf("\n");
    // for (i = 0; i < n - 1; i++) {
    //     swapped = false;
    //     for (j = 0; j < n - 1 - i; j++) {
    //         if (data[j] > data[j + 1]) {
    //             temp = data[j];
    //             data[j] = data[j + 1];
    //             data[j + 1] = temp;
    //             swapped = true;
    //         }
    //     }
    //     if (swapped == false) {
    //         printf("(在第 %d 趟后提前结束)\n", i + 1);
    //         break;
    //     }
    // }
    // printf("排序后数组: ");
    // for (i = 0; i < n; i++) {
    //     printf("%d ", data[i]);
    // }
    // printf("\n");

    //Program5



    //Program???
    const int MAX_ROWS=15;
    int triangle[MAX_ROWS][MAX_ROWS];
    int rows;
    printf("int rows:%d",MAX_ROWS);
    scanf("%d",&rows);
    if(rows<1||rows>MAX_ROWS){
        printf("Error");
        return 1;
    }
    for(i=0;i<rows;i++){
        for(j=0;j<=i;j++){
            if(j==0||j==i){
                triangle[i][j]=1;
            }else{
                triangle[i][j]=triangle[i-1][j-1]+triangle[i-1][j];
            }
        }
    }
    printf("Print %d")
}


