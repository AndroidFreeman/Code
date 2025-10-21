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
    int n;
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
    
}
