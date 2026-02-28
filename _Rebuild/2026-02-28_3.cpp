/*
 * @Date: 2026-02-28 17:27:31
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 19:22:30
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_3.cpp
 */
#include <bits/stdc++.h>
using namespace std;

bool compare(pair<int, int> a, pair<int, int> b) {
    if (a.first != b.first) return a.first > b.first;
    return a.second < b.second;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int total, winner;
    if (!(cin >> total >> winner)) return 0;
    vector<pair<int, int>> students;
    for (int i = 0; i < total; i++) {
        int id, score;
        cin >> id >> score;
        students.emplace_back(score, id);
    }

    sort(students.begin(), students.end(), compare);
    students.erase(unique(students.begin(), students.end()), students.end());

    int real_winner = min(winner, (int)students.size());
    for (int i = 0; i < real_winner; i++) {
        cout << " " << students[i].second << " " << students[i].first << endl;
    }
}