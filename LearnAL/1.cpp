//单向动态链表
#include<iostream>
using namespace std;
struct Node{
    int data;
    Node*next;
};
int main(){
    int n,m;
    scanf("%d%d",&n,&m);
    Node*head,*p,*now,*prev;
    head=new Node;
    head.data=1;
    head.next=NULL;
    now=head;
    for(int i=2;i<=n;i++){
        p=new Node;
        p.data=i,p.next=NULL;
        now.next=p;
        now=p;
    }
    now=head,prev=head;
    while((n--)>1){
        for(int i=1;i<m;i++){
            prev=now;
            now=now.next;
        }
        cout<<now.data;
        prev.next=now.next;
        delete now;
        now=prev.next;
    }
    cout<<now.data;
    delete now;
}
