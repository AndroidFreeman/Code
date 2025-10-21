//VectorLearn
#include <bits/stdc++.h>
using namespace std;
void printVector(const vector<int>& vec) {
    for (int element : vec) {
        cout << element << " ";
    }
    cout << std::endl;
}
int main(){
    cout << "Hello" << endl;
    vector<int> a(10);
    iota(a.begin(),a.end(),1);
    printVector(a);
    vector<string> string_vec(10, "hello");
    vector<string> b(string_vec.begin(), string_vec.end());
    a.push_back(199);
    printVector(a);
    int size=a.size();
    bool isEmpty=a.empty();
    cout<<isEmpty<<endl;
    a.insert(a.end(),10,5);
    printVector(a);
    a.pop_back();
    printVector(a);
    a.erase(a.begin()+12,a.begin()+22);
    printVector(a);
    vector<int> temp(10);
    iota(temp.begin(),temp.end(),1);
    a.insert(a.end(),temp.begin(),temp.end());
    printVector(a);
    a.erase(a.begin());
    printVector(a);
    a.resize(11);
    printVector(a);
    reverse(a.begin(),a.end());
    printVector(a);
    sort(a.begin(),a.end());
    printVector(a);
    a.clear();

    //Program HDU4841
    vector<int> table;
    int n,m;
    n=2;
    m=3;
    while(1){
        table.clear();
        table.resize(2*n);
        iota(table.begin(),table.end(),0);
        int pos=0;
        for(int i=0;i<n;i++){
            pos=(pos+m-1)%table.size();
            table.erase(table.begin()+pos);
        }
        int i=0; int j=0;
        for(i=0;i<2*n;i++){
            if(!(i%50)&&i){
                cout<<endl;
            }
            if(j<table.size()&&i==table[j]){
                j++;
                cout<<"G";
            }else{
                cout<<"B";
            }
        }
        cout<<endl;
        break;
    }
    //Program HDU4841 Using Pointer
    struct Node{
        int data;
        Node* next;
    }nodes;
    //Step1
    Node* head = new Node{0, nullptr};
    Node* current = head;
    for (int i = 1; i < 2 * n; i++) {
        current->next = new Node{i, nullptr};
        current = current->next;
    }
    current->next = head;
    //Step2
    Node* prev=current;
    for(int i=0;i<n;i++){
        for(int count=0;count<m-1;count++){
            prev=prev->next;
        }
        Node* node_to_delete=prev->next;
        prev->next=node_to_delete->next;
        delete node_to_delete;
    }
    //Step3
    head=prev->next;
    vector<bool> is_survivor(2*n,false);
    current=head;
    for(int i=0;i<n;i++){
        is_survivor[current->data]=true;
        current=current->next;
    }
    for(int i=0;i<2*n;i++){
        if(is_survivor[i]){
            cout<<"G";
        }else{
            cout<<"B";
        }
    }
    cout<<endl;
    //Step4
    current=head;
    for(int i=0;i<n;i++){
        Node* next_node=current->next;
        delete current;
        current=next_node;
    }
    return 0;
}

