#include <bits/stdc++.h>
using namespace std;

void printVector(const std::vector<int>& vec) {
    for (int element : vec) {
        std::cout << element << " ";
    }
    std::cout << std::endl;
}

int main(){
    cout << "Hello" << endl;
    vector<int> a(10);
    iota(a.begin(),a.end(),1);
    printVector(a);
    vector<string> string_vec(10, "hello");
    vector<string> b(string_vec.begin(), string_vec.end());
    a.push_back(199);
    printVector(a);
    int size=a.size();
    bool isEmpty=a.empty();
    cout<<isEmpty<<endl;
    a.insert(a.end(),10,5);
    printVector(a);
    a.pop_back();
    printVector(a);
    a.erase(a.begin()+12,a.begin()+22);
    printVector(a);
    vector<int> temp(10);
    iota(temp.begin(),temp.end(),1);
    a.insert(a.end(),temp.begin(),temp.end());
    printVector(a);
    
}
