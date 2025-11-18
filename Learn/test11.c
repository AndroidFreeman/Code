#include <stdio.h>
const int N = 10;
int main() {
    int arr[N];
    int *p;
    int temp;
    // 1. 使用指针循环输入
    printf("请输入 %d 个整数: \n", N);
    for (p = arr; p < arr + N; p++) {
        scanf("%d", p); // p 本身就是地址
    }
    printf("--- 原始数组 ---\n");
    for (p = arr; p < arr + N; p++) {
        printf("%d ", *p);
    }
    printf("\n");
    // 2. 步骤一: 找到最大值, 并将其与第一个元素 (arr[0]) 交换
    // 假设第一个元素 (arr[0]) 就是最大值
    int *pMax = arr;
    // 从第二个元素 (arr[1]) 开始遍历, 寻找真正的最大值
    for (p = arr + 1; p < arr + N; p++) {
        if (*p > *pMax) {
            pMax = p; // pMax 指向新的最大值地址
        }
    }
    // 执行交换: 把 pMax 指向的值和 arr[0] (即 *arr) 的值交换
    temp = *arr;
    *arr = *pMax;
    *pMax = temp;
    printf("--- 最大值 %d 放到首位后 ---\n", *arr);
    for (p = arr; p < arr + N; p++) {
        printf("%d ", *p);
    }
    printf("\n");
    // 3. 步骤二: 找到最小值, 并将其与最后一个元素 (arr[N-1]) 交换
    // 注意: 最小值一定不在 arr[0] (那里现在是最大值)
    // 所以我们从 arr[1] 开始搜索
    int *pMin = arr + 1; // 假设第二个元素 (arr[1]) 是最小值
    // 遍历范围: 从 arr[2] 到 arr[N-1]
    for (p = arr + 2; p < arr + N; p++) {
        if (*p < *pMin) {
            pMin = p; // pMin 指向新的最小值地址
        }
    }
    // 获取指向最后一个元素 (arr[N-1]) 的指针
    int *pLast = arr + N - 1;
    // 执行交换: 把 pMin 指向的值和 pLast 指向的值交换
    temp = *pLast;
    *pLast = *pMin;
    *pMin = temp;
    printf("--- 最小值 %d 放到末位后 (最终结果) ---\n", *pLast);
    for (p = arr; p < arr + N; p++) {
        printf("%d ", *p);
    }
    printf("\n");
}
