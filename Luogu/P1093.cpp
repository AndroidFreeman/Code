#include<bits/stdc++.h>
using namespace std;

struct stu{
    int chi,math,eng,index,total;
}stu[305];

bool compare(stu a,stu b){
    if(a.total!=b.total){
        return a.total>b.total;
    }
    if(a.chi!=b.chi){
        return a.chi>b.chi;
    }
    if(a.index!=b.index){
        return a.index<b.index;
    }
}

int main(){
    int total;
    cin>>total;
    for(int i=0;i<total;i++){
        cin>>stu[i].chi>>stu[i].math>>stu[i].eng;
        stu[i].index=i+1;
        stu[i].total=stu[i].chi+stu[i].math+stu[i].eng;
    }

    sort(stu,stu+total,compare);

    for(int i=0;i<5;i++){
        cout<<stu[i].index<<" "<<stu[i].total<<endl;
    }
}
