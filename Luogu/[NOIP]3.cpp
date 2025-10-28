//P1563
#include<bits/stdc++.h>
using namespace std;
int main(){
    //input
    int peo,com;
    cin>>peo>>com;
    int way[peo];
    string name[peo];
    for(int i=0;i<peo;i++){
        cin>>way[i]>>name[i];
    }

    //process
    int now=0;
    for(int i=0;i<com;i++){
        int a,s;
        cin>>a>>s;
        if(way[now]==a){
            now=now-s;
        }else{
            now=now+s;
        }
        now=(now%peo+peo)%peo;
    }
    cout<<name[now];
}
