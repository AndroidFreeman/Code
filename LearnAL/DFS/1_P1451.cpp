/*
 * @Date: 2026-03-08 21:28:16
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-08 21:56:48
 * @FilePath: /Code_Sync/LearnAL/DFS/1_P1451.cpp
 */
#include <bits/stdc++.h>
using namespace std;

int n,m,ans=0;
vector<string> matrix;

void dfs(int x,int y){
    if(x<0||x>=n||y<0||y>=m||matrix[x][y]=='0') return;

    matrix[x][y]='0';

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
    for (int i = 0; i < n; i++) cin >> matrix[i];
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            if(matrix[i][j]!='0'){
                ans++;
                dfs(i,j);
            }
        }
    }
    
    cout<<ans<<endl;
 
    return 0;
}