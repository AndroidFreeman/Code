//linked list
#include<bits/stdc++.h>
using namespace std;
struct ListNode{
    int val;
    ListNode* next;
};
ListNode *newListNode(int val){
    ListNode* node;
    node=(ListNode*)malloc(sizeof(ListNode));
    node->val=val;
    node->next=NULL;
    return node;
}
void insert(ListNode *n0;ListNode*P){
    ListNode *n1=n0->next;
    P->next=n1;
    n0->next=P;
}
int main(){
    ListNode* n0=newListNode(1);
    ListNode* n1=newListNode(3);
    ListNode* n2=newListNode(2);
    ListNode* n3=newListNode(5);
    ListNode* n4=newListNode(4);
    n0->next=n1;
    n1->next=n2;
    n2->next=n3;
    n3->next=n4;
}
