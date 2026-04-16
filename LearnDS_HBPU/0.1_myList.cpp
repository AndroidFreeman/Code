/*
 * @Date: 2026-03-23 08:28:39
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-16 10:17:32
 * @FilePath: /Code/LearnDS_HBPU/0.1_myList.cpp
 */
#include <bits/stdc++.h>

using namespace std;

#define MAXSIZE 100

struct Book {
    int ISBN;
    string name;
    double price;
};

struct SqList {
    Book* elem;
    int length;
};

typedef Book ElemType;

string InitList(SqList& L) {
    L.elem = new ElemType[MAXSIZE];
    if (!L.elem) return "存储分配失败";
    L.length = 0;
    return "OK";
}

string GetElem(SqList L, int i, ElemType& e) {
    if (i < 1 || i > L.length) return "Error";
    e = L.elem[i - 1];
    return "OK";
}

int LocateElem(SqList L, ElemType e) {
    for (int i = 0; i < L.length; i++)
        if (L.elem[i].ISBN == e.ISBN) return i + 1;
    return 0;
}

string ListInsert(SqList& L, int i, ElemType e) {
    if ((i < 1) || (i > L.length + 1)) return "Error";
    if (L.length == MAXSIZE) return "Error";
    for (int j = L.length - 1; j >= i - 1; j--) L.elem[j + 1] = L.elem[j];
    L.elem[i - 1] = e;
    L.length++;
    return "OK";
}

string ListDelete(SqList& L, int i) {
    if ((i < 1) || (i > L.length)) return "Error";
    for (int j = i; j <= L.length - 1; j++) L.elem[j - 1] = L.elem[j];
    L.length--;
    return "OK";
}

int main() {
    // ios::sync_with_stdio(false);
    // cin.tie(0);
    // cout.tie(0);

    SqList L;
    if (InitList(L) != "OK") {
        cout << "初始化失败！" << endl;
        return 0;
    }

    int choice;
    while (true) {
        cout << "\n======= 图书管理系统 =======" << endl;
        cout << "1. 插入新书" << endl;
        cout << "2. 删除书籍" << endl;
        cout << "3. 按ISBN查找" << endl;
        cout << "4. 获取指定位置书籍" << endl;
        cout << "5. 显示所有书籍" << endl;
        cout << "0. 退出系统" << endl;
        cout << "请输入指令: ";

        if (!(cin >> choice)) break;

        if (choice == 1) {
            int i;
            ElemType e;
            cout << "请输入插入位置 (1 到 " << L.length + 1 << "): ";
            cin >> i;
            cout << "请输入 ISBN: ";
            cin >> e.ISBN;
            cout << "请输入书名: ";
            cin >> e.name;
            cout << "请输入价格: ";
            cin >> e.price;
            cout << "操作结果: " << ListInsert(L, i, e) << endl;
        } else if (choice == 2) {
            int i;
            cout << "请输入要删除的位置: ";
            cin >> i;
            cout << "操作结果: " << ListDelete(L, i) << endl;
        } else if (choice == 3) {
            ElemType e;
            cout << "请输入要查找的 ISBN: ";
            cin >> e.ISBN;
            int pos = LocateElem(L, e);
            if (pos)
                cout << "找到该书，在第 " << pos << " 个位置" << endl;
            else
                cout << "未找到相关书籍" << endl;
        } else if (choice == 4) {
            int i;
            ElemType e;
            cout << "请输入位置: ";
            cin >> i;
            if (GetElem(L, i, e) == "OK") {
                cout << "书籍信息: " << e.ISBN << " | " << e.name << " | "
                     << e.price << endl;
            } else {
                cout << "位置无效" << endl;
            }
        } else if (choice == 5) {
            cout << "当前共有 " << L.length << " 本书：" << endl;
            for (int j = 0; j < L.length; j++) {
                cout << "[" << j + 1 << "] " << L.elem[j].ISBN << "\t"
                     << L.elem[j].name << "\t" << L.elem[j].price << "\n";
            }
        } else if (choice == 0) {
            cout << "程序已退出" << endl;
            break;
        } else {
            cout << "无效指令，请重新输入" << endl;
        }
    }

    delete[] L.elem;
    return 0;
}
