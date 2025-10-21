#include<bits/stdc++.h>
using namespace std;
int main(){
    string input_string;
    getline(cin,input_string);

    stack<char> trans_string;
    for(char c:input_string){
        trans_string.push(c);
    }

    string answer_string="";
    while(!trans_string.empty()){
        answer_string+=trans_string.top();
        trans_string.pop();
    }

    cout<<answer_string<<endl;
}
