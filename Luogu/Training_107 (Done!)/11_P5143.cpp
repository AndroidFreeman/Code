/*
 * @Date: 2026-03-07 22:17:57
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-07 22:29:55
 * @FilePath: /Code_Sync/Luogu/Traning_107/11_P5143.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct Point {
    int x, y, z;
};
bool compare(const Point& a, const Point& b) { return a.z < b.z; }
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int total;
    cin >> total;
    double answer = 0;
    vector<Point> point(total);
    for (int i = 0; i < total; i++) {
        cin >> point[i].x >> point[i].y >> point[i].z;
    }
    sort(point.begin(), point.end(), compare);
    for (int i = 1; i < total; i++) {
        answer += (sqrt(pow((point[i].x - point[i - 1].x), 2) +
                        pow((point[i].y - point[i - 1].y), 2) +
                        pow((point[i].z - point[i - 1].z), 2)));
    }
    cout << fixed << setprecision(3) << answer;

    return 0;
}