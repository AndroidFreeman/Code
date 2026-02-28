/*
 * @Date: 2026-02-28 10:39:39
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 11:26:38
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_1.cpp
 */

// CPP STL Learn

#include <bits/stdc++.h>
using namespace std;
int main()
{
    // vector
    vector<int> arr;
    vector<int> arr1(5);
    vector<int> arr2(5, 10);
    vector<vector<int>> mat1(5, vector<int>(10));
    vector<vector<vector<int>>> dp2(5, vector<vector<int>>(10, vector<int>(10)));

    arr.push_back(1);
    // after: arr = [1]
    arr.push_back(2);
    // after: arr = [1, 2]

    for (int i = 0; i < arr.size(); i++)
    {
        cout << arr[i] << endl;
    }

    arr.pop_back();
    // after: arr = [1]
    arr.pop_back();
    // after: arr = []

    arr = {1, 2, 3};
    for (int i = 0; i < arr.size(); i++)
    {
        cout << arr[i] << endl;
    }
    arr.clear();

    cout<<arr.empty()<<"!"<<endl;
    arr.push_back(1);
    cout<<arr.empty()<<"?"<<endl;

    vector<int> ar(10,10);
    for(int i:ar){
        cout<<i<<" ";
    }
    cout<<endl;
    ar.resize(5);
    for(int i:ar){
        cout<<i<<" ";
    }
    cout<<endl;

    
}