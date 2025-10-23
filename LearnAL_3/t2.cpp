#include<bits/stdc++.h>
using namespace std;
int main(){
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    stack<char> s;
    string s_in;
    getline(cin,s_in);
    // for(int i=0;i<s_in.size();i++){
    //     s.push(s_in[i]);
    // }
    // for(int i=0;i<s_in.size();i++){
    //     cout<<s.top();
    //     s.pop();
    // }
    for(char ch:s_in){
        if(ch==' '){
            while(!s.empty()){
                cout<<s.top();
                s.pop();
            }
            cout<<' ';
        }else{
            s.push(ch);
        }
    }
    while(!s.empty()){
        cout<<s.top();
        s.pop();
    }
    cout<<endl;
}

