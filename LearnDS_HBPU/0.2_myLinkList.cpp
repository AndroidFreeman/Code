/*
 * @Date: 2026-03-23 09:24:16
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-26 10:17:16
 * @FilePath: /Code/LearnDS_HBPU/0.2_myLinkList.cpp
 */
#include <bits/stdc++.h>

using namespace std;

typedef long long ElemType;

typedef struct LNode {
    ElemType data;
    struct LNode* next;
} LNode, *LinkList;

bool InitList(LinkList& L) {
    L = new LNode;
    L->next = nullptr;
    return true;
}

bool GetElem(LinkList L, int i, ElemType& e) {
    LNode* p = L->next;
    int j = 1;
    while (p && j < i) {
        p = p->next;
        j++;
    }
    if (!p || j > i) return false;
    e = p->data;
    return true;
}

LNode* LocateElem(LinkList L, ElemType e) {
    LNode* p = L->next;
    while (p && p->data != e) p = p->next;
    return p;
}

bool LinkInsert(LinkList& L, int i, ElemType e) {
    LNode* p = L;
    int j = 0;
    while (p && (j < i - 1)) {
        p = p->next;
        j++;
    }
    if (!p || j > i - 1) return false;
    LNode* s = new LNode;
    s->data = e;
    s->next = p->next;
    p->next = s;
    return true;
}

bool ListDelete(LinkList& L, int i) {
    LNode* p = L;
    int j = 0;
    while ((p->next) && (j < i - 1)) {
        p = p->next;
        j++;
    }
    if (!(p->next) || (j > i - 1)) return false;
    LNode* q = p->next;
    p->next = q->next;
    delete q;
    return true;
}

void PrintList(LinkList L) {
    LNode* p = L->next;
    if (!p) {
        cout << "当前链表为空" << endl;
        return;
    }
    cout << "当前链表内容: ";
    while (p) {
        cout << p->data << " -> ";
        p = p->next;
    }
    cout << "NULL" << endl;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(0);
    cout.tie(0);

    LinkList L;
    InitList(L);

    int choice;
    while (true) {
        cout << "\n======= 单链表管理系统 =======" << endl;
        cout << "1. 插入元素" << endl;
        cout << "2. 删除元素" << endl;
        cout << "3. 按值查找" << endl;
        cout << "4. 获取指定位置元素" << endl;
        cout << "5. 打印整个链表" << endl;
        cout << "0. 退出程序" << endl;
        cout << "请输入您的选择: " << endl;

        if (!(cin >> choice)) break;

        if (choice == 1) {
            int i;
            ElemType e;
            cout << "请输入插入位置和数值: " << endl;
            cin >> i >> e;
            if (LinkInsert(L, i, e))
                cout << "插入成功！" << endl;
            else
                cout << "插入失败，位置非法" << endl;
        } else if (choice == 2) {
            int i;
            cout << "请输入要删除的位置: " << endl;
            cin >> i;
            if (ListDelete(L, i))
                cout << "删除成功！" << endl;
            else
                cout << "删除失败，位置不存在" << endl;
        } else if (choice == 3) {
            ElemType e;
            cout << "请输入要查找的数值: " << endl;
            cin >> e;
            LNode* res = LocateElem(L, e);
            if (res)
                cout << "查找成功，元素地址为: " << res << endl;
            else
                cout << "查找失败，该值不在链表中" << endl;
        } else if (choice == 4) {
            int i;
            ElemType e;
            cout << "请输入获取位置: " << endl;
            cin >> i;
            if (GetElem(L, i, e))
                cout << "第 " << i << " 个元素的值为: " << e << endl;
            else
                cout << "获取失败，位置无效" << endl;
        } else if (choice == 5) {
            PrintList(L);
        } else if (choice == 0) {
            cout << "正在退出系统..." << endl;
            break;
        } else {
            cout << "无效选择，请重新输入" << endl;
        }
    }

    LNode* p = L;
    while (p) {
        LNode* q = p;
        p = p->next;
        delete q;
    }

    return 0;
}
