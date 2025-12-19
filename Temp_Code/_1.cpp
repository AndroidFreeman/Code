struct ListNode{
    int val;
    ListNode *next;
    ListNode(int x):val(x),next(nullptr){}
};
void insert(ListNode *n0,ListNode *P){
    ListNode *n1=n0->next;
    P->next=n1;
    n0->next=P;
}
