/*
 * @Date: 2026-04-16 11:31:38
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-16 11:43:13
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/0.2_myLinkList_Rewrite.cpp
 */
#include <bits/stdc++.h>
using namespace std;
struct Book {
    string name;
    int ISBN;
    double price;
};

typedef Book ElemType;

struct Node {
    ElemType Data;
    Node* Next;
};

typedef Node* LinkList;

bool LinkListInit(LinkList& _List) {
    _List = new Node;
    if (!_List) return false;
    _List->Next = nullptr;
    return true;
};

bool LinkListGet(LinkList& _List, ElemType& Book, int Index) {
    Node* Printer = _List->Next;
    int index = 1;
    while (Printer && index < Index) {
        Printer = Printer->Next;
        index++;
    }
    if (!Printer || index > Index) return false;
    Book = Printer->Data;
    return true;
}
