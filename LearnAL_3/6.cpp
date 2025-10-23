//Sort()
#include<bits/stdc++.h>
using namespace std;
void vector_out(vector<int> &temp){
    for(int i=0;i<temp.size();i++){
        cout<<temp[i]<<" ";
    }
    cout<<endl;
}
int main(){
    vector<int> a={3,9,4,5,8,1,0};
    sort(a.rbegin(),a.rend());
    vector_out(a);
    sort(a.begin(),a.end());
    vector_out(a);
}
