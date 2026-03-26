/*
 * @Date: 2026-03-26 10:20:20
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 19:29:34
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/0.2_myLinkList.cpp
 */
#include <bits/stdc++.h>
using namespace std;

typedef long long ElemType;

typedef struct LNode {
    ElemType data;
    LNode* next;
} LNode, *LinkList;

bool CreateList_Head(LinkList& Head, long long n) {
    if (!(Head = new LNode)) return false;
    Head->next = nullptr;

    for (long long i = n; i > 0; i--) {
        LNode* newNode = new LNode;
        ElemType dataInput;

        cin >> dataInput;
        newNode->data = dataInput;

        newNode->next = Head->next;
        Head->next = newNode;
    }
    return true;
}

bool CreateList_Tail(LinkList& Head, long long n) {
    if (!(Head = new LNode)) return false;
    Head->next = nullptr;

    LNode* tailNode = Head;

    for (int i = 0; i < n; i++) {
        LNode* newNode = new LNode;
        ElemType dataInput;

        cin >> dataInput;
        newNode->data = dataInput;

        newNode->next = nullptr;
        tailNode->next = newNode;

        tailNode = newNode;
    }
    return true;
}

bool FindElem(LinkList& Head, ElemType& elem, long long target) {
    LNode* searchNode = Head->next;
    long long index = 1;

    while (searchNode && index < target) {
        searchNode = searchNode->next;
        index++;
    }

    if (!searchNode || index > target) return false;
    elem = searchNode->data;

    return true;
}

bool InsertElem(LinkList& Head, ElemType& elem, long long target) {
    LNode* insertNode = new LNode;
    insertNode = Head;
    long long index = 1;

    while (insertNode && index < target) {
        insertNode = insertNode->next;
        index++;
    }
    if (!insertNode || index > target) return false;

    LNode* insertNodes = new LNode;
    insertNodes->data = elem;
    insertNodes->next = insertNode->next;
    insertNode->next = insertNodes;

    return true;
}

bool DeleteElem(LinkList& Head, ElemType& elem, long long target) {
    LNode* deleteNode = Head;

    long long index = 0;
    while (deleteNode->next && index < target - 1) {
        deleteNode = deleteNode->next;
        index++;
    }
    if (!deleteNode || index > target) return false;

    auto deleteNodes = deleteNode->next;
    deleteNode->next = deleteNodes->next;
    elem = deleteNodes->data;
    delete deleteNode;

    return true;
}

// bool MergeList(LinkList& List1, LinkList& List2, LinkList& List3) {}