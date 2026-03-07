/*
 * @Date: 2026-03-07 16:08:12
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 16:33:37
 * @FilePath: /Code_Sync/Luogu/Traning_107/6_P1781.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct Process {
    int id;
    string vote;
};
bool compare(Process& a, Process& b) {
    if (a.vote.size() != b.vote.size()) {
        return a.vote.size() < b.vote.size();
    }
    return a.vote < b.vote;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int candidate;
    if (!(cin >> candidate)) return 0;
    vector<Process> process(candidate);
    for (int i = 0; i < candidate; i++) {
        cin >> process[i].vote;
        process[i].id = i + 1;
    }
    // sort(process.begin(),process.end(),compare);
    // reverse(process.begin(),process.end());
    // cout<<process[0].id<<endl<<process[0].vote;
    auto winner = max_element(process.begin(), process.end(), compare);
    cout << winner->id << endl << winner->vote;
    return 0;
}