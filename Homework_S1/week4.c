#include<stdio.h>
#define STUDENTS 5
#define SUBJECTS 5
int main(){
//    Program1
//     int a[15], low, high, mid, search;
//     int found = 0;
//     printf("Enter a number:\n");
//     for (int i = 0; i < 15; i++) {
//         scanf("%d", &a[i]);
//     }
//     printf("Enter search: ");
//     scanf("%d", &search);
//     low = 0;
//     high = 14;
//     while (low <= high) {
//         mid = low + (high - low) / 2;
//         if (search == a[mid]) {
//             printf("Find it!, %d\n", mid + 1);
//             found = 1;
//             break;
//         } else if (search > a[mid]) {
//             low = mid + 1;
//         } else {
//             high = mid - 1;
//         }
//     }
//     if (!found) {
//         printf("Doesn't exist.\n");
//     }

    //Program2
//     int M=4;
//     int N=5;
//     int a[M],b[N],c[M+N],i,j,k;
//     for(i=0;i<M;i++){
//         scanf("%d",&a[i]);
//     }for(j=0;j<N;j++){
//         scanf("%d",&b[j]);
//     }for(i=j=k=0;i<M&&j<N;){
//         if(a[i]<=b[j]){
//             c[k++]=a[i++];
//         }else{
//             c[k++]=b[j++];
//         }
//     }
//     while(i<M){
//         c[k++]=a[i++];
//     }
//     while(j<N){
//         c[k++]=b[j++];
//     }
//     for(k=0;k<M+N;k++){
//         printf("%d",c[k]);
//     }
//     printf("\n");

    //Program3
//     int class_number = 70;
//     int score[class_number];
//     long long count = 0;
//     double average;
//     int temp;
//     int low_score[class_number];
//     int actual_student_count = 0;
//     int low_score_count = 0;
//     printf("Score:");
//     for (int i = 0; i < class_number; i++) {
//         scanf("%d", &temp);
//         if (temp > 100) {
//             printf("Error\n");
//             continue;
//         }
//         if (temp == -1) {
//             break;
//         }
//         score[actual_student_count] = temp;
//         count = count + temp;
//         actual_student_count++;
//     }
//     if (actual_student_count == 0) {
//         printf("Error\n");
//         return 0;
//     }
//     average = (double)count / actual_student_count;
//     for (int i = 0; i < actual_student_count; i++) {
//         if (score[i] < average) {
//             low_score[low_score_count] = score[i];
//             low_score_count++;
//         }
//     }
//     printf("lower:%d\n", low_score_count);
//     for (int i = 0; i < low_score_count; i++) {
//         printf("%d ", low_score[i]);
//     }
//     printf("\n");
//     printf("Ave: %.2f\n", average);
//     printf("Total: %lld\n", count);
//     printf("Students: %d\n", actual_student_count);

    //Program4
//     int data[] = {5, 1, 4, 2, 8, 3, 7, 6};
//     int n = sizeof(data) / sizeof(data[0]);
//     int i, j;
//     int temp;
//     int swapped;
//     printf("original:");
//     for (i = 0; i < n; i++) {
//         printf("%d", data[i]);
//     }
//     printf("\n");
//     for (i = 0; i < n - 1; i++) {
//         swapped = 0;
//         for (j = 0; j < n - 1 - i; j++) {
//             if (data[j] > data[j + 1]) {
//                 temp = data[j];
//                 data[j] = data[j + 1];
//                 data[j + 1] = temp;
//                 swapped = 1;
//             }
//         }
//         if (swapped == 0) {
//             printf("(...%d...)\n", i + 1);
//             break;
//         }
//     }
//     printf("sorted: ");
//     for (i = 0; i < n; i++) {
//         printf("%d ", data[i]);
//     }
//     printf("\n");

    //Program5
//     int matrix[3][4];
//     for (int i = 0; i < 3; i++) {
//         for (int j = 0; j < 4; j++) {
//             scanf("%d", &matrix[i][j]);
//         }
//     }
//     int max_value = matrix[0][0];
//     int max_row = 0;
//     int max_col = 0;
//     for (int i = 0; i < 3; i++) {
//         for (int j = 0; j < 4; j++) {
//             if (matrix[i][j] > max_value) {
//                 max_value = matrix[i][j];
//                 max_row = i;
//                 max_col = j;
//             }
//         }
//     }
//     printf("Max: %d\n", max_value);
//     printf("Line: %d\n", max_row + 1);
//     printf("Row: %d\n", max_col + 1);


    //Program6
//	 int MAX_ROWS=15;
//     int triangle[MAX_ROWS][MAX_ROWS];
//     int rows;
//     printf("int rows:%d",MAX_ROWS);
//     scanf("%d",&rows);
//     if(rows<1||rows>MAX_ROWS){
//         printf("Error");
//         return 1;
//     }
//     for(int i=0;i<rows;i++){
//         for(int j=0;j<=i;j++){
//             if(j==0||j==i){
//                 triangle[i][j]=1;
//             }else{
//                 triangle[i][j]=triangle[i-1][j-1]+triangle[i-1][j];
//             }
//         }
//     }
//    for (int i = 0; i < rows; i++) {
//         for (int j = 0; j <= i; j++) {
//             printf("%-6d", triangle[i][j]);
//         }
//         printf("\n");
//     }

    //Program7
//    float scores[STUDENTS][SUBJECTS];
//    const char *subject_names[SUBJECTS] = {"Sub1", "Sub2", "Sub3", "Sub4", "Sub5"};
//    printf("--- Enter Scores ---\n");
//    for (int i = 0; i < STUDENTS; i++) {
//        printf("Enter scores for S%d:\n", i + 1);
//        for (int j = 0; j < SUBJECTS; j++) {
//            printf("  %s: ", subject_names[j]);
//            scanf("%f", &scores[i][j]);
//        }
//        printf("\n");
//    }
//    printf("\n--- Subject Averages ---\n");
//    for (int j = 0; j < SUBJECTS; j++) {
//        float subject_sum = 0;
//        for (int i = 0; i < STUDENTS; i++) {
//            subject_sum += scores[i][j];
//        }
//        float subject_avg = subject_sum / STUDENTS;
//        printf("%s ave: %.2f\n", subject_names[j], subject_avg);
//    }
//    printf("\n--- Student Averages ---\n");
//    for (int i = 0; i < STUDENTS; i++) {
//        float student_sum = 0;
//        for (int j = 0; j < SUBJECTS; j++) {
//            student_sum += scores[i][j];
//        }
//        float student_avg = student_sum / SUBJECTS;
//        printf("S%d ave: %.2f\n", i + 1, student_avg);
//    }
}


