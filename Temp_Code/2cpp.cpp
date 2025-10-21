#include<bits/stdc++.h>
using namespace std;
int main(){
    string os;
    getline(cin,os);

    stack<char> ss;
    for(char c:os){
        ss.push(c);
    }

    string ts="";
    while(!ss.empty()){
        ts+=ss.top();
        ss.pop();
    }

    cout<<ts;
}
