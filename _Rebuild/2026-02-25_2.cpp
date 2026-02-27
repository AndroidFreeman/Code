/*
   【问题描述】给定一个有n（n≥1）个整数的序列，要求求出其中最大连续子序列的和。
    例如：
    序列（-2，11，-4，13，-5，-2）的最大子序列和为20
    序列（-6，2，4，-7，5，3，2，-1，6，-9，10，-2）的最大子序列和为16。
    规定一个序列最大连续子序列和至少是0，如果小于0，其结果为0。
*/

#include <bits/stdc++.h>
using namespace std;
int main() {
    int n;
    if (!(cin >> n)) return 0;
    vector<int> a(n);
    for (int i = 0; i < n; i++) {
        cin >> a[i];
    }
    long long max_so_far = 0;
    long long current_sum = 0;
    for (int i = 0; i < n; i++) {
        current_sum += a[i];
        if (current_sum < 0) {
            current_sum = 0;
        }
        if (max_so_far < current_sum) {
            max_so_far = current_sum;
        }
    }
    cout << max_so_far << endl;
    return 0;
}