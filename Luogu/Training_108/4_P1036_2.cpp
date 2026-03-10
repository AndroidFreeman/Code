/*
 * @Date: 2026-03-09 21:21:54
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-09 21:27:08
 * @FilePath: /Code_Sync/Luogu/Training_108/4_P1036_2.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int n, m, answer = 0;
vector<int> number;
bool prime(int x) {
    if (x == 1) return false;
    for (int i = 2; i * i <= n; i++)
        if (x % i == 0) return false;
    return true;
}
void dfs(int index, int next, int sum) {
    if (index == m) {
        if (prime(sum)) {
            answer++;
        }
        return;
    }

    for (int i = next; i < n; i++) {
        dfs(index + 1, i + 1, sum + number[i]);
    }
    return;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    cin>>n>>m;
    for(int i=0;i<n;i++) cin>>number[i];
    dfs(0,0,0);
    cout<<answer;

    return 0;
}