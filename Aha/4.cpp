//Queue

#include<bits/stdc++.h>
using namespace std;

struct myqueue{
    vector<int> data{100};
    int head;
    int tail;
};

int main(){
    struct myqueue q;
    q.head=1;
    q.tail=1;
    for(int i=1;i<=9;i++){
        cin>>q.data[q.tail];
        q.tail++;
    }
    while(q.head<q.tail){
        cout<<q.data[q.head];
        q.head++;
        q.data[q.tail]=q.data[q.head];
        q.tail++;
        q.head++;
    }
}
