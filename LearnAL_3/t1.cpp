//HDU4841
#include<bits/stdc++.h>
using namespace std;
int main(){
    int n,m;
    while(cin>>n>>m&&(m||n)){
        vector<int> all_people(2*n);
        iota(all_people.begin(),all_people.end(),0);
        int now=0;
        for(int i=0;i<n;i++){
            now=(now+m-1)%all_people.size();
            //Don't understand at first.
            all_people.erase(all_people.begin()+now);
        }
        //Now,I can't understand the next part at all.
        int j=0;
        for(int i=0;i<2*n;i++){
        //Pointer1
            if(!(i%50)&&i){
                cout<<endl;
            }
            if(j<n&&i==all_people[j]){
                j++;
                //Pointer2
                cout<<"G";
            }else{
                cout<<"B";
            }
        }
        cout<<endl;
    }
}
