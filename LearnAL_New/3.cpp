//List
#include<bits/stdc++.h>
using namespace std;
int main(){
    //HDU 1276

    //Step1
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
        //把数字全压入链表

        //Step2
        while(mylist.size()>3){
        //条件罢了
            int num=1;
            for(it=mylist.begin();it!=mylist.end;){
            //淘汰一轮的过程
                if(num++%k==0){
                //如果num是k的倍数 这个数就完蛋了
                    it=mylist.erase(it);
                    //删除这个元素 迭代器指向下一个元素
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
