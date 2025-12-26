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
int main(){

}
