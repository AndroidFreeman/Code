/*
 * @Date: 2026-03-07 22:34:04
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 22:40:43
 * @FilePath: /Code_Sync/Luogu/Traning_107/12_P1104.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct People {
    string name;
    int yy, mm, dd, id;
};
bool compare(People a, People b) {
    if (a.yy != b.yy) return a.yy < b.yy;
    if (a.mm != b.mm) return a.mm < b.mm;
    if (a.dd != b.dd) return a.dd < b.dd;
    return a.id > b.id;
}
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total;
    cin >> total;
    vector<People> people(total);
    for (int i = 0; i < total; i++) {
        cin >> people[i].name >> people[i].yy >> people[i].mm >> people[i].dd;
        people[i].id = i;
    }
    sort(people.begin(), people.end(), compare);
    for (int i = 0; i < total; i++) {
        cout << people[i].name << endl;
    }
    return 0;
}