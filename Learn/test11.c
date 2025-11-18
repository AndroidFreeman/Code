#include <stdio.h>

int main() {
    int Q;
    printf("请输入数组大小 Q: ");
    scanf("%d", &Q);
    int tmpp[Q]; // 使用 VLA (可变长度数组)

    // 1. 输入
    printf("请输入 %d 个整数: \n", Q);
    for (int i = 0; i < Q; i++) {
        scanf("%d", &tmpp[i]);
    }

    // 2. 查找最大和最小值的 *地址*
    // 关键: p_max 和 p_min 必须指向数组内的地址
    int* p_max = &tmpp[0]; // 假设第一个元素是最大值
    int* p_min = &tmpp[0]; // 假设第一个元素也是最小值

    int* p;
    for (p = &tmpp[1]; p < &tmpp[Q]; p++) {
        if (*p > *p_max) {
            p_max = p;
        }
        if (*p < *p_min) {
            p_min = p;
        }
    }

    // 3. 交换

    // 陷阱处理: 如果 p_max 或 p_min 正好指向
    // 我们要交换的目标位置 (tmpp[0] 或 tmpp[Q-1])，
    // 我们必须小心更新它们，否则交换会出错。

    // 3.1 交换最大值到 tmpp[0]
    int temp = tmpp[0];
    tmpp[0] = *p_max;
    *p_max = temp;

    // 3.2 交换最小值到 tmpp[Q-1]

    // 检查: 如果最小值原本在 tmpp[0] (现在被最大值占了)
    // 那么 p_min 此时指向的位置 (tmpp[0]) 存的是最大值，
    // 但它真正的地址是 p_max (因为被换过去了)。
    if (p_min == &tmpp[0]) {
        p_min = p_max;
    }

    int* p_last = &tmpp[Q - 1];
    temp = *p_last;
    *p_last = *p_min;
    *p_min = temp;

    printf("处理后的数组:\n");
    for (int i = 0; i < Q; i++) {
        printf("%d ", tmpp[i]);
    }
    printf("\n");
    return 0;
}
