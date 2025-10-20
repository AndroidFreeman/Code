//单向静态链表
#include<iostream>
using namespace std;
const int N=105;
struct Node{
    int id,nextid;
}Nodes[N];
int main(){
    int n,m;
    cin>>n>>m;
    Nodes[0].nextid=1;
    int now=1,prev=1;
    while((n--)>1){
        for(int i=1;i<m;i++){
            prev=now;
            now=Nodes[now].nextid;
        }
        cout<<Nodes[now].id<<" ";
        Nodes[prev].nextid=Nodes[now].nextid;
        now=Nodes[prev].nextid;
    }
    cout<<Nodes[now].nextid<<endl;
}
