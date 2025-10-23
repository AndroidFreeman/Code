#include<bits/stdc++.h>
using namespace std;

struct Node{
    int data;
    Node* next;
};

int main(){
    int n,m;
    cin>>n>>m;
    Node head=new Node(0,nullptr);
    Node now=head;
    for(int i=1;n<2*n;i++){
        Node person=new Node(i,nullptr);
        now->next=person;
        now=person;
    }
    now->next=head;

    if()
}
