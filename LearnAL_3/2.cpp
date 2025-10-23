//Stack
#include<bits/stdc++.h>
using namespace std;
int main(){
    stack<int> s;
    s.push(1);
    s.push(2);
    s.push(3);
    int s_top=s.top();
    cout<<s_top<<endl;
    s.pop();
    s_top=s.top();
    cout<<s_top<<endl;
    int s_size=s.size();
    cout<<s_size<<endl;
    bool s_isEmpty=s.empty();
    cout<<s_isEmpty<<endl;
    //HDU 1062
    int n=1;
    char ch;
    scanf("%d",&n);
    getchar();
    while(n--){
        stack<char> s;
        while(true){
            ch=getchar();
            if(ch==' '||ch=='\n'||ch==EOF){
                while(!s.empty()){
                    cout<<s.top();
                    s.pop();
                }
                if(ch=='\n'||ch==EOF){
                    break;
                }
                cout<<" ";
            }else{
                s.push(ch);
            }
        }
        cout<<endl;
    }


    //StackTest
    //Step0
    locale::global(locale(""));
    //Step1
    cout<<"Enter a string:";
    string os;
    getline(cin,os);
    //Step2
    stack<char> cs;
    for(char c:os){
        cs.push(c);
    }
    //Step3
    string rs="";
    while(!cs.empty()){
        rs+=cs.top();
        cs.pop();
    }
    //Step4
    cout<<rs<<endl;

    //Queue
    queue<int> q;
    q.push(1);
    q.push(2);
    q.push(3);
    int q1=q.front();
    cout<<q1<<endl;
    q.pop();
    q1=q.front();
    cout<<q1<<endl;

    //Priority Queue
    int q2=q.top();
}
