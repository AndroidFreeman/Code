/*
 * @Date: 2026-03-09 10:44:29
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 10:47:33
 * @FilePath: /Code_Sync/LearnAL/DFS/1_P1451_4.cpp
 */
#include <bits/stdc++.h>
using namespace std;
vector<string> matrix;
int n, m, answer = 0;

void dfs(int x, int y) {
    if (x < 0 || y < 0 || x >= n || y >= m || matrix[x][y] == '0') return;
    matrix[x][y] = 0;
    int dx[] = {-1, 1, 0, 0};
    int dy[] = {0, 0, -1, 1};
    for (int i = 0; i < 4; i++) {
        dfs(x + dx[i], y + dy[i]);
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if (!(cin >> n >> m)) return -1;
    for (int i = 0; i < n; i++) cin >> matrix[i];
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            if (matrix[i][j] != '0') {
                answer++;
                dfs(i, j);
            }
        }
    }
    cout << answer;

    return 0;
}