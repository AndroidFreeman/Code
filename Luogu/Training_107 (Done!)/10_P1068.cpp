/*
 * @Date: 2026-03-07 21:50:12
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 22:15:17
 * @FilePath: /Code_Sync/Luogu/Traning_107/10_P1068.cpp
 */
#include <bits/stdc++.h>
using namespace std;

struct People {
    int id, score;
};
bool compare(People a, People b) {
    if (a.score != b.score) return a.score > b.score;
    return a.id < b.id;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total, getin;
    cin >> total >> getin;
    vector<People> people(total);
    for (int i = 0; i < total; i++) {
        cin >> people[i].id >> people[i].score;
    }
    int getout = getin * 1.5;
    int answer = 0;
    sort(people.begin(), people.end(), compare);
    for (int i = 0; i < total - 1; i++) {
        if (people[i].score >= people[getout - 1].score) answer++;
    }
    cout << people[getout - 1].score << ' ' << answer << endl;
    for (int i = 0; i < answer; i++) {
        cout << people[i].id << ' ' << people[i].score << endl;
    }

    return 0;
}