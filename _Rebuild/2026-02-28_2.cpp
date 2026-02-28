/*
 * @Date: 2026-02-28 17:03:42
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 19:25:57
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_2.cpp
 */

/*
 * 题目 1：【入门】百米赛跑排名 (Basic Pair & Sort)
 * ------------------------------------------------------------------------
 * 【题目背景】
 * 某校运动会进行百米赛跑，由于计时系统故障，原始成绩单录入混乱。
 * 请你编写程序整理选手的排名。
 * * 【输入】
 * 1. 第一行输入一个整数 n（运动员人数）。
 * 2. 接下来的 n 行，每行包含两个整数：学号 (ID) 和 成绩 (Score)。
 * * 【排序规则】
 * 1. 成绩越小（快）的选手排名越靠前（成绩升序）。
 * 2. 如果两个选手的成绩相同，则学号越小越靠前（学号升序）。
 * * 【要求】
 * 1. 成绩为 0 表示选手缺赛，需从结果中剔除。
 * 2. 使用 vector<pair<int, int>> 存储数据。
 * * 【输出】
 * 每一行输出：排名 学号 成绩
 */

#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);

    int n;
    cin >> n;
    vector<pair<int, int>> a;
    for (int i = 0; i < n; i++) {
        int id, score;
        cin >> id >> score;
        if (score > 0) {
            a.push_back({score, id});
        }
    }
    sort(a.begin(), a.end());
    a.erase(unique(a.begin(), a.end()), a.end());

    for (int i = 0; i < a.size(); i++) {
        cout << i + 1 << " " << a[i].second << " " << a[i].first << endl;
    }
}
