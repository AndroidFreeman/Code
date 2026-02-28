/*
 * @Date: 2026-02-28 10:39:39
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 17:02:02
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_1.cpp
 */

// CPP STL Learn
// vector
#include <algorithm>
#include <bits/stdc++.h>
using namespace std;

void print(vector<int> v){
    for(int i:v){
        cout<<i<<" ";
    }
    cout<<endl;
}

int main()
{
    //Basic STL 

    vector<int> arr;
    vector<int> arr1(5);
    vector<int> arr2(5, 10);
    vector<vector<int>> mat1(5, vector<int>(10));
    vector<vector<vector<int>>> dp2(5, vector<vector<int>>(10, vector<int>(10)));

    arr.push_back(1);
    // after: arr = [1]
    arr.push_back(2);
    // after: arr = [1, 2]
    print(arr);
    arr.pop_back();
    // after: arr = [1]
    arr.pop_back();
    // after: arr = []

    arr = {1, 2, 3};
    print(arr);
    arr.clear();

    cout << arr.empty() << "!" << endl;
    arr.push_back(1);
    cout << arr.empty() << "?" << endl;

    vector<int> ar(10, 10);
    print(ar);
    ar.resize(5);
    print(ar);

    // vector<int> b;
    // b.reserve(1e9);
    // for (int i = 0; i < 1e9; i++)
    // {
    //     b.push_back(i);
    // }

    vector<int> v={3,1,4,1,5};
    v.insert(v.begin()+1,1);
    
    print(v);

    
    //Now we can try sth new

    sort(v.begin(),v.end(),less<int>());
    print(v);
    sort(v.begin(),v.end(),greater<int>());
    print(v);
    reverse(v.begin(),v.end());
    cout<<"sort:";
    print(v);

    auto itt=unique(v.begin(),v.end());
    v.erase(itt,v.end());
    // v.erase(unique(v.begin(),v.end()),v.end());
    print(v);
    auto it=v.begin();
    cout<<*it<<endl;

    int max_val=*max_element(v.begin(),v.end());
    cout<<max_val<<endl;
    int min_val = *min_element(v.begin(), v.end());
    cout<<min_val<<endl;

    int aaa=v.back();
    v.back()=50;
    v.front()=100;

    v.assign(5,100);
    print(v);

    //We can try sth high level

    vector<pair<int,int>> va;
    va.push_back({94,1001});
    va.emplace_back(91,1002);
    sort(va.begin(),va.end());
    
    vector<pair<int,int>> students;
    students.emplace_back(95,101);
    students.emplace_back(91,102);
    students.emplace_back(97,103);
    sort(students.begin(),students.end());
    for(int i=0;i<students.size();i++){
        cout<<students[i].second<<" "<<students[i].first<<endl;
    }
    cout<<endl;
}