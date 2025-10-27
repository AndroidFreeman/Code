//P2670
#include<bits/stdc++.h>
using namespace std;
//preparation
int n, m;
char gmap[105][105];
int gnum[105][105];
int i, j;
//main
int main(){
    //input
    cin>>n>>m;
    for(i=1;i<=n;i++){
        for(j=1;j<=m;j++){
            cin>>gmap[i][j];
        }
    }
    //game
    for(i=1;i<=n;i++){
        for(j=1;j<=m;j++){
            if(gmap[i][j]=='*'){
                gnum[i-1][j]+=1;
                gnum[i-1][j-1]+=1;
                gnum[i-1][j+1]+=1;
                gnum[i][j-1]+=1;
                gnum[i][j+1]+=1;
                gnum[i+1][j-1]+=1;
                gnum[i+1][j]+=1;
                gnum[i+1][j+1]+=1;
            }
        }
    }
    //output
    for(i=1;i<=n;i++){
        for(j=1;j<=m;j++){
            if(gmap[i][j]=='*'){
                cout<<'*';
            }else{
                cout<<gnum[i][j];
            }
        }
        puts("");
    }
    return 0;
}
