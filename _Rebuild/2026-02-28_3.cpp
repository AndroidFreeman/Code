/*
 * @Date: 2026-02-28 17:27:31
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 19:25:35
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_3.cpp
 */

/*
 * 题目 2：【进阶】奖学金评定 (Custom Compare & Unique)
 * ------------------------------------------------------------------------
 * 【题目背景】
 * 学校根据学生的综合积分发放奖学金，由于系统可能存在重复录入，你需要先去重再排序。
 * * 【输入】
 * 1. 第一行输入两个整数 n（总人数）和 k（奖学金名额）。
 * 2. 接下来的 n 行，每行包含两个整数：学号 (ID) 和 积分 (Points)。
 * * 【排序规则】
 * 1. 积分越高（大）的选手排名越靠前（积分降序）。
 * 2. 如果积分相同，则学号越小越靠前（学号升序）。
 * * 【要求】
 * 1. 必须使用 unique 和 erase 剔除“完全重复”（学号和积分均相同）的记录。
 * 2. 如果录取名额 k 大于实际剩余人数，则输出所有剩余选手。
 * 3. 手写 bool compare 函数实现“一降一升”逻辑。
 * * 【输出】
 * 每一行输出：排名 学号 积分
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