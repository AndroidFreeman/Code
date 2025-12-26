// //linked list
// #include<bits/stdc++.h>
// using namespace std;
// struct ListNode{
//     int val;
//     ListNode* next;
// };
// ListNode *access(ListNode* head,int index){
//     for(int i=0;i<index;i++){
//         if(head==NULL)
//             return NULL;
//         head=head->next;
//     }
//     return head;
// }
// int find(ListNode *head,int targer){
//     int index=0;
//     while(head){
//         if(head->val==targer)
//             return index;
//         head=head->next;
//         index++;
//     }
//     return -1;
// }
// ListNode *newListNode(int val){
//     ListNode* node;
//     node=(ListNode*)malloc(sizeof(ListNode));
//     node->val=val;
//     node->next=NULL;
//     return node;
// }
// void removeItem(ListNode* n0{
//     if(!n0->next){
//         return;
//     }
//     ListNode *P=n0->next;
//     ListNode *n1=P->next;
//     n0->next=n1;
//     free(P);
// })
// void insert(ListNode *n0;ListNode*P){
//     ListNode *n1=n0->next;
//     P->next=n1;
//     n0->next=P;
// }
// int main(){
//     ListNode* n0=newListNode(1);
//     ListNode* n1=newListNode(3);
//     ListNode* n2=newListNode(2);
//     ListNode* n3=newListNode(5);
//     ListNode* n4=newListNode(4);
//     n0->next=n1;
//     n1->next=n2;
//     n2->next=n3;
//     n3->next=n4;
// }













#include<bits/stdc++.h>
using namespace std;
struct ListNode{
    int val;
    ListNode* next;
};

ListNode* newListNode(int val){
    ListNode* node=(ListNode*)malloc(sizeof(ListNode));
    if(!node) return nullptr;
    node->val=val;
    node->next=nullptr;
    return node;
}

void pushBack(ListNode** head,int val){
    ListNode* newNode=newListNode(val);
    if(*head==nullptr){
        *head=newNode;
        return;
    }
    ListNode* curr=*head;
    while(curr->next!=nullptr){
        curr=curr->next;
    }
    curr->next=newNode;
}

int main(){
    LinkList* head;
    head->next=nullptr;
}
