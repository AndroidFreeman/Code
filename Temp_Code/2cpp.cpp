#include<bits/stdc++.h>
using namespace std;
int main(){
    string os;
    getline(cin,os);
    stack<char> ss;
    for(char c:os){
        ss.push(os);
    }
    string ts="";
    while(!ss.empty()){
        ts=cs.top();
        ss.pop();
    }
    cout<<ts;
}
