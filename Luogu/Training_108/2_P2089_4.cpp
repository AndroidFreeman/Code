/*
 * @Date: 2026-03-09 13:19:26
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 13:26:41
 * @FilePath: /Code_Sync/Luogu/Training_108/2_P2089_4.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int n;
vector<int> temp(10);
vector<vector<int>> matrix;

void dfs(int step, int weight) {
    if (step == 10) {
        if (weight == n) {
            vector<int> plan;
            for (int i = 0; i < 10; i++) plan.push_back(temp[i]);
            matrix.push_back(plan);
        }
        return;
    }

    for (int i = 0; i < 3; i++) {
        temp[step] = i;
        dfs(step + 1, weight + 1);
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    cin >> n;
    dfs(0, 0);
    cout << matrix.size() << endl;

    // 输出每一种方案
    for (auto v : matrix) {
        for (int i = 0; i < 10; i++) {
            cout << v[i] << " ";
        }
        cout << endl;
    }

    return 0;
}