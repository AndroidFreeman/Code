#include<bits/stdc++.h>
using namespace std;

struct Node{
    int data;
    Node* next;
};

int main(){
    int n,m;
    while(cin>>n>>m){
        Node head=new Node(0,nullptr);
        Node now=head;
        for(int i=1;n<2*n;i++){
            Node person=new Node(i,nullptr);
            now->next=person;
            now=person;
        }
        now->next=head;

        Node* prev=now;
        for(int i=0;i<n;i++){
            for(int j=0;j<m-1;j++){
                prev=prev->next;
            }
            Node* node_del=prev->next;
            prev->next=node_del->next;
            delete node_del;
        }

        head=prev->next;
        vector<bool> is_sur(n,false);
        now=head;
        for(int i=0;i<n;i++){
        
        }
    }

}
