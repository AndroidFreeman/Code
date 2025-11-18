#include <stdio.h>

const int N = 10;

// (函数1: input_array 和 函数3: output_array 保持不变)
void input_array(int *arr, int n) {
    printf("请输入 %d 个整数: \n", n);
    for (int i = 0; i < n; i++) {
        scanf("%d", arr + i);
    }
}

void output_array(int *arr, int n) {
    printf("处理后的数组为: \n");
    for (int i = 0; i < n; i++) {
        printf("%d ", *(arr + i));
    }
    printf("\n");
}


// --- 2. 函数(2): 对换 (简单逻辑版) ---
void swap_array(int *arr, int n) {
    int temp;
    int *pMin = arr;
    for (int i = 1; i < n; i++) {
        if (*(arr + i) < *pMin) {
            pMin = arr + i;
        }
    }
    temp = *arr;
    *arr = *pMin;
    *pMin = temp;
    int *pMax = arr;
    for (int i = 1; i < n; i++) {
        if (*(arr + i) > *pMax) {
            pMax = arr + i;
        }
    }
    int *pLast = arr + n - 1;
    temp = *pLast;
    *pLast = *pMax;
    *pMax = temp;
}


// --- 主函数 ---
int main() {
    int arr[N];

    input_array(arr, N);
    swap_array(arr, N);
    output_array(arr, N);

    return 0;
}
