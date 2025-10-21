#include<bits/stdc++.h>
using namespace std;
int main(){
    // string os;
    // getline(cin,os);

    // stack<char> ss;
    // for(char c:os){
    //     ss.push(c);
    // }

    // string ts="";
    // while(!ss.empty()){
    //     ts+=ss.top();
    //     ss.pop();
    // }

    // cout<<ts;

    string input_string;
    getline(cin,input_string);

    stack<char> trans_string;
    for(char c:input_string){
        trans_string.push(c);
    }

    string answer_string="";
    for(!trans_string.empty()){
        answer_string+=trans_string.top();
        trans_string.pop();
    }

    cout<<trans_string<<endl;
}
