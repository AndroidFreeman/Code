#include <stdio.h>
int main() {
    int Q;
    scanf("%d", &Q);
    int tmpp[Q];
    int* p;
    int temp;
    for (p = tmpp; p < tmpp + Q; p++) {
        scanf("%d", p);
    }
    int* p_max = tmpp;
    for (p = tmpp + 1; p < tmpp + Q; p++) {
        if (*p > *p_max) {
            p_max = p;
        }
    }
    temp = *tmpp;
    *tmpp = *p_max;
    *p_max = temp;

    int* p_min = tmpp + 1;
    for (p = tmpp + 2; p < tmpp + Q; p++) {
        if (*p < *p_min) {
            p_min = p;
        }
    }
    int* p_last = tmpp + Q - 1;

    temp = *p_last;
    *p_last = *p_min;
    *p_min = temp;

    for (p = tmpp; p < tmpp + Q; p++) {
        printf("%d ", *p);
    }
    printf("\n");
}
