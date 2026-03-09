/*
 * @Date: 2026-03-09 13:28:24
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 13:36:26
 * @FilePath: /Code_Sync/Luogu/Training_108/2_P2089_5.cpp
 */

#include <bits/stdc++.h>
using namespace std;
int n;
vector<vector<int>> matrix;
vector<int> now(10, 0);

void dfs(int step, int weight) {
    if (step == 10) {
        if (weight == n) {
            vector<int> plan;
            for (int i = 0; i < 10; i++) plan.push_back(now[i]);
            matrix.push_back(plan);
        }
        return;
    }

    for (int i = 1; i <= 3; i++) {
        now[step] = i;
        dfs(step + 1, weight + 1);
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    cin >> n;
    dfs(0, 0);
    cout << matrix.size() << endl;
    for (auto v : matrix) {
        for (int i = 0; i < 10; i++) {
            cout << v[i] << " ";
        }
        cout << endl;
    }

    return 0;
}