/*
 * @Date: 2026-02-28 18:50:28
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-02-28 19:22:42
 * @FilePath: /Code/Code_Sync/_Rebuild/2026-02-28_4.cpp
 */

/*
 * 题目 3：【强化】全能运动员选拔 (Three-Level Struct)
 * ------------------------------------------------------------------------
 * 【题目背景】
 * 选拔全能运动员需要参考总分和体育专项分，当多项数据持平时，需要严谨的级联排序。
 * * 【输入】
 * 1. 第一行输入两个整数 n（总人数）和 k（录取人数）。
 * 2. 接下来的 n 行，每行包含三个整数：学号 (ID)、总分 (Total)、体育分 (PE)。
 * * 【排序规则（优先级从高到低）】
 * 1. 总分越高越靠前（总分降序）。
 * 2. 总分相同时，体育分越高越靠前（体育分降序）。
 * 3. 前两者均相同时，学号越小越靠前（学号升序）。
 * * 【要求】
 * 1. 定义 struct Student 结构体管理数据。
 * 2. 剔除总分为 0 的选手，并处理重复录入。
 * 3. 手写 is_equal 判等函数配合 unique 进行结构体去重。
 * 4. 必须在读入 n 之后再进行 vector.reserve(n) 优化。
 * * 【输出】
 * 每一行输出：排名 学号 总分 体育分
 */

#include <bits/stdc++.h>
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