#include<stdio.h>
#define N 100
void max_min(int a[], int n, int *max, int *min);
int main(void)
{
//  int b[N], i, big, small;
//  printf("Enter %d numbers: ", N);
//  for (i = 0; i < N; i++)
//  scanf("%d", &b[i]);

//  max_min(b, N, &big, &small);
//  printf("Largest: %d\n", big);
//  printf("Smallest: %d\n", small);
//  return 0;
// }
// void max_min(int a[], int n, int *max, int *min)
// {
//  int i;
//  *max = *min = a[0];
//  for (i = 1; i < n; i++) {
//  if (a[i] > *max)
//  *max = a[i];
//  else if (a[i] < *min)
//  *min = a[i];
//  }

    // printf("Enter a message:");
    // char ch[N];
    // char ch1[N];
    // char c;
    // int i=0;
    // int tmpi=0;
    // while(i<N-1&&(c=getchar())!='\n'){
    //     ch[i]=c;
    //     i++;
    // }
    // char tmp;
    // while(tmpi<=i){
    //     ch1[tmpi]=ch[i-tmpi-1];
    //     tmpi++;
    // }
    // printf("%s\n",ch1);

    printf("Enter a message:");
    char ch[N];
    char chT[N];
    char ch1T[N];
    char c;
    char*t1=ch;
    while((c=getchar())!='\n'){
        *t1=c;
        t1++;
    }
    *t1='\0';

}
