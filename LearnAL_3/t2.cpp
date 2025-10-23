#include<bits/stdc++.h>
using namespace std;
int main(){
    stack<char> s;
    string s_in;
    getline(cin,s_in);
    for(int i=0;i<s_in.size();i++){
        s.push(s_in[i]);
    }
    for(int i=0;i<s_in.size();i++){
        cout<<s.top();
        s.pop();
    }
}
