//List
#include<bits/stdc++.h>
using namespace std;
int main(){
    //HDU 1276
    int t,n;
    cin>>t;
    //测试几轮
    while(t--){
        cin>>n;
        //总人数
        int k=2;
        //抓人
        list<int> mylist;
        list<int>::iterator it;
        //迭代器 
        for(int i=1;i<=n;i++){
            mylist.push_back(i);
        }
        while(mylist.size()>3){
            int num=1;
            for(it=mylist.begin();it!=mylist.end;){
                if(num++%k==0){
                    it=mylist.erase(it);
                }else{
                    it++;
                }
            }
            k==2?k=3:k=2;
        }
        for(it=mylist.begin();it!=mylist.end();it++){
            if(it!=mylist.begin()){
                cout<<" ";
            }
            cout<<*it;
        }
        cout<<endl;
    }
}
