#include<bits/stdc++.h>
using namespace std;
int main(){
    vector<int> num1;
    vector<int> nums={1,3,2,5,4};
    int num=nums[4];
    nums[4]=0;
    nums.push_back(1);
    nums.push_back(5);
    nums.insert(nums.begin()+3,6);
    nums.erase(nums.begin()+3);
}
