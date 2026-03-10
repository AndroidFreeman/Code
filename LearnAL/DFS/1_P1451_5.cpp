/*
 * @Date: 2026-03-10 22:12:53
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-10 22:44:35
 * @FilePath: /Code_Sync/LearnAL/DFS/1_P1451_5.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int n,m;
vector<string> matrix;
void dfs(int x,int y){
    if(matrix[x][y]=='0') return;
    for(int i=0;i<4;i++){
        
    }
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if(!(cin>>n>>m)) return -1;
    matrix.resize(n);
    for(int i=0;i<n;i++) cin>>matrix[i];
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(matrix[i][j]!='0') {
                dfs(i,j);
            }
        }
    }
    return 0;
}