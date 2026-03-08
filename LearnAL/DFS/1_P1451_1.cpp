/*
 * @Date: 2026-03-08 22:26:58
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-08 22:34:08
 * @FilePath: /Code_Sync/LearnAL/DFS/1_P1451_1.cpp
 */
#include <bits/stdc++.h>
using namespace std;

vector<string> matrix;
int answer=0;
int n,m;
void dfs(int x,int y){
    if(x>=n||x<0||y>=m||y<0||matrix[x][y]=='0') return;

    matrix[x][y]=0;
    int dx[]={-1,1,0,0};
    int dy[]={0,0,-1,1};

    for(int i=0;i<4;i++){
        dfs(x+dx[i],y+dy[i]);
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    if(!(cin>>n>>m)) return -1;
    matrix.resize(n);
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            cin>>matrix[i][j];
        }
    }
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(matrix[i][j]!='0'){
                answer++;
                dfs(i,j);
            }
        }
    }
    cout<<answer;

    return 0;
}