#include<bits/stdc++.h>
using namespace std;
int main(){
    //before
    std::ios::sync_with_stdio(false);
    cin.tie(0);
    //input
    int stu_num;
    int que_num;
    cin>>stu_num>>que_num;
    vector<int> stu_id(stu_num);
    vector<int> stu_que(que_num);
    for(int i=0;i<stu_num;i++){
        cin>>stu_id[i];
    }
    for(int i=0;i<que_num;i++){
        cin>>stu_que[i];
    }

    //process
    for(int i=0;i<=que_num;i++){
        int ask_index=stu_que[i];
        cout<<stu_id[ask_index-1]<<endl;
    }
}
