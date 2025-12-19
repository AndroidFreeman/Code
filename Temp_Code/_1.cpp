struct ListNode{
    int val;
    ListNode *next;
    ListNode(int x):val(x),next(nullptr){}
};
ListNode *n0=new ListNode(1);
ListNode *n1=new ListNode(3);
ListNode *n2=new ListNode(2);
ListNode *n3=new ListNode(5);
ListNode *n4=new ListNode(4);
n0->next=n1;
n1->next=n2;
n2->next=n3;
n3->next=n4;
void insert(ListNode *n0,ListNode *P){
    ListNode *n1=n0->next;
    P->next=n1;
    n0->next=P;
}
