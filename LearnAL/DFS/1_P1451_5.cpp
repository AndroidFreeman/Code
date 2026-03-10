/*
 * @Date: 2026-03-10 22:12:53
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-10 22:25:13
 * @FilePath: /Code_Sync/LearnAL/DFS/1_P1451_5.cpp
 */
#include <bits/stdc++.h>
using namespace std;
int n,m;
int answer=0;
vector<string> matrix;

void dfs(int x,int y){
    if(matrix[x][y]!='0'){
        answer++;
        return;
    }
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(matrix[i][j]!='0'){
                matrix[i][j]='0';
                dfs(i,j);
            }
        }
    }
    return;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if(!(cin>>n>>m)) return -1;
    matrix.resize(4);
    for(int i=0;i<4;i++) cin>>matrix[i];
    dfs(0,0);
    cout<<answer;

    return 0;
}