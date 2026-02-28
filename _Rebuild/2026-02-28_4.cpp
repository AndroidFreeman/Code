/*
 * @Date: 2026-02-28 18:50:28
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 19:22:42
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_4.cpp
 */
#include <bits/stdc++.h>

#include <algorithm>
#include <vector>
using namespace std;

struct Students {
    int id, total, pe;
};

bool is_equal(Students a, Students b) {
    return a.id == b.id && a.total == b.total && a.pe == b.pe;
}

bool compare(Students a, Students b) {
    if (a.total != b.total) return a.total > b.total;
    if (a.pe != b.pe) return a.pe > b.pe;
    return a.id < b.id;
}

int main() {
    cin.tie(0);
    std::ios::sync_with_stdio(false);

    int number, people;
    vector<Students> students;
    if (!(cin >> number >> people)) return 0;
    students.reserve(number);
    for (int i = 0; i < number; i++) {
        int id, total, pe;
        cin >> id >> total >> pe;
        if (total <= 0) continue;
        students.push_back({id, total, pe});
    }
    sort(students.begin(), students.end(), compare);
    students.erase(unique(students.begin(), students.end(), is_equal),
                   students.end());

    int real_number = min((int)students.size(), people);
    for (int i = 0; i < real_number; i++) {
        cout << students[i].id << " " << students[i].total << endl;
    }
}