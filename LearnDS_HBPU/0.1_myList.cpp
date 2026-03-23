/*
 * @Date: 2026-03-23 08:28:39
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-23 08:53:59
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
    if (!L.elem) return "Error";
    L.length = 0;
    return "OK";
}

string GetElem(SqList L, int i, ElemType& e) {
    if (i < 1 || i > L.length) return "Error";
    e = L.elem[i - 1];
    return "OK";
}

int LocateElem(SqList L, ElemType e) {
    for (int i = 0; i < L.length; i++) {
        if (L.elem[i].ISBN == e.ISBN) return i + 1;
    }
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
    ios::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);

    SqList L;
    InitList(L);

    int op;
    while (cin >> op) {
        if (op == 1) {
            int i;
            ElemType e;
            cin >> i >> e.ISBN >> e.name >> e.price;
            cout << ListInsert(L, i, e) << endl;
        } else if (op == 2) { 
            int i;
            cin >> i;
            cout << ListDelete(L, i) << endl;
        } else if (op == 3) { 
            ElemType e;
            cin >> e.ISBN;
            int pos = LocateElem(L, e);
            if (pos) cout << "Position: " << pos << endl;
            else cout << "Not Found" << endl;
        } else if (op == 4) { // 
            for (int j = 0; j < L.length; j++) {
                cout << L.elem[j].ISBN << " " << L.elem[j].name << " " << L.elem[j].price << endl;
            }
        } else if (op == 0) {
            break;
        }
    }

    delete[] L.elem;
    return 0;
}
