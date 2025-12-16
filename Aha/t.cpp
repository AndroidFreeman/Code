#include<iostream>
using namespace std;
struct Node{
    int data;
    Node* next;
}LNode,*LinkList;
void Insert(){

}
void Init(LinkList *h){

}
void Print(LinkList h){
    LNode *p;
    for(p=h->next;p!=NULL;p=p->next){
        cout<<p->data;
    }
    cout<<endl;
}
int main(){
    LinkList head;
    LNode *p,*q;
    Init(head);
}
