/*
 * @Date: 2026-04-16 10:14:24
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-16 11:20:16
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/0.1_myList_Rewrite.cpp
 */
#include <bits/stdc++.h>
using namespace std;

struct Books {
    int ISBN;
    string name;
    double price;
};
const int Size = 64;

typedef Books ElemType;

struct myList {
    ElemType* elem;
    long long length;
};

bool myListInit(myList& _List) {
    _List.elem = new ElemType[Size];
    if (!_List.elem) return false;
    _List.length = 0;
    return true;
}

bool myListGet(myList& _List, ElemType& Book, int Index) {
    if (Index < 1 || Index > _List.length) return false;
    Book = _List.elem[Index - 1];
    return true;
}

int myListLocate(myList& _List, ElemType Book) {
    for (int Index = 0; Index < _List.length; Index++) {
        if (_List.elem[Index].ISBN == Book.ISBN) return Index + 1;
    }
    return 0;
}

bool myListInsert(myList& _List, ElemType Book, int Index) {
    if (Index < 1 || Index > _List.length + 1) return false;
    if (_List.length >= Size) return false;
    for (int index = _List.length - 1; index >= Index - 1; index--)
        _List.elem[index + 1] = _List.elem[index];
    _List.elem[Index - 1] = Book;
    _List.length++;
    return true;
}

bool myListDelete(myList& _List, int Index) {
    if (Index < 1 || Index > _List.length) return false;
    for (int index = Index; index < _List.length; index++)
        _List.elem[index - 1] = _List.elem[index];
    _List.length--;
    return true;
}

int main() {
    myList _List;
    if (!myListInit(_List)) {
        cout << "False";
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
            int Index;
            ElemType Book;
            cout << "请输入插入位置 (1 到 " << _List.length + 1 << "): ";
            cin >> Index;
            cout << "请输入 ISBN: ";
            cin >> Book.ISBN;
            cout << "请输入书名: ";
            getline(cin >> ws, Book.name);
            cout << "请输入价格: ";
            cin >> Book.price;
            cout << "操作结果: " << myListInsert(_List, Book, Index) << endl;
        } else if (choice == 2) {
            int Index;
            cout << "请输入要删除的位置: ";
            cin >> Index;
            cout << "操作结果: " << myListDelete(_List, Index) << endl;
        } else if (choice == 3) {
            ElemType Book;
            cout << "请输入要查找的 ISBN: ";
            cin >> Book.ISBN;
            int position = myListLocate(_List, Book);
            if (position)
                cout << "找到该书，在第 " << position << " 个位置" << endl;
            else
                cout << "未找到相关书籍" << endl;
        } else if (choice == 4) {
            int Index;
            ElemType Book;
            cout << "请输入位置: ";
            cin >> Index;
            if (myListGet(_List, Book, Index)) {
                cout << "书籍信息: " << Book.ISBN << " | " << Book.name << " | "
                     << Book.price << endl;
            } else {
                cout << "位置无效" << endl;
            }
        } else if (choice == 5) {
            cout << "当前共有 " << _List.length << " 本书：" << endl;
            for (int j = 0; j < _List.length; j++) {
                cout << "[" << j + 1 << "] " << _List.elem[j].ISBN << "\t"
                     << _List.elem[j].name << "\t" << _List.elem[j].price
                     << "\n";
            }
        } else if (choice == 0) {
            cout << "程序已退出" << endl;
            break;
        } else {
            cout << "无效指令，请重新输入" << endl;
        }
    }

    delete[] _List.elem;
    return 0;
}