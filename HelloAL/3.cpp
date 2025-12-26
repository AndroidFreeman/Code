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
    int count=0;
    for(int i=0;i<nums.size();i++){
        count+=nums[i];
    }
    count=0;
    for(int num:nums){
        count+=num;
    }
    vector<int> nums1={6,8,7,10,9};
    nums.insert(nums.end(),nums1.begin(),nums1.end());
    sort(nums.begin(),nums.end());
}
