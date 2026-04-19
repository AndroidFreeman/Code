#include <bits/stdc++.h>
using namespace std;

// 数据结构定义 [cite: 16, 17]
struct ElemType {
    int num;        // 学号
    char name[20];  // 姓名
    char sex[3];    // 性别
    char tel[14];   // 联系电话
    char qq[12];    // QQ号
};

struct LNode {
    ElemType data;
    LNode* next;
};
typedef LNode* LinkList;

// --- 核心功能函数 ---

// 初始化带头结点的单链表
void InitList_L(LinkList& L) {
    L = new LNode;
    L->next = nullptr;
    cout << "单链表通讯录初始化成功。" << endl;
}

// 输入一条数据 [cite: 5]
void inputOne(ElemType& x) {
    cout << "请输入: 学号 姓名 性别 手机号 QQ号 (以空格隔开)" << endl;
    cin >> x.num >> x.name >> x.sex >> x.tel >> x.qq;
}

// 输出一条数据 [cite: 5]
void outputOne(ElemType x) {
    cout << left << setw(10) << x.num << setw(10) << x.name << setw(6) << x.sex
         << setw(15) << x.tel << setw(12) << x.qq << endl;
}

// 在单链表L中第i个位置前插入元素e
int ListInsert_L(LinkList& L, int i, ElemType e) {
    LNode* p = L;
    int j = 0;
    while (p && j < i - 1) {  // 寻找第i-1个结点
        p = p->next;
        ++j;
    }
    if (!p || j > i - 1) return 0;  // i小于1或者大于表长+1

    LNode* s = new LNode;
    s->data = e;
    s->next = p->next;
    p->next = s;
    return 1;
}

// 在单链表L中删除第i个元素，并由e返回其值
int ListDelete_L(LinkList& L, int i, ElemType& e) {
    LNode* p = L;
    int j = 0;
    while (p->next && j < i - 1) {  // 寻找第i-1个结点
        p = p->next;
        ++j;
    }
    if (!(p->next) || j > i - 1) return 0;  // 删除位置不合理

    LNode* q = p->next;
    p->next = q->next;
    e = q->data;
    delete q;
    return 1;
}

// 比较学号或姓名相同的函数 [cite: 5, 18]
int fun1(ElemType a, ElemType b) { return strcmp(a.name, b.name) == 0; }
int fun2(ElemType a, ElemType b) { return a.num == b.num; }

// 从链表中查找与给定元素值相同的元素
LinkList LocateElem_L(LinkList L, ElemType e, int (*op)(ElemType, ElemType)) {
    LNode* p = L->next;
    while (p) {
        if ((*op)(p->data, e)) return p;
        p = p->next;
    }
    return nullptr;
}

// 输出全部记录 [cite: 5]
void output(LinkList L) {
    LNode* p = L->next;
    if (!p) {
        cout << "通讯录为空。" << endl;
        return;
    }
    cout << left << setw(10) << "学号" << setw(10) << "姓名" << setw(6)
         << "性别" << setw(15) << "手机号" << setw(12) << "QQ号" << endl;
    cout << string(53, '-') << endl;
    while (p) {
        outputOne(p->data);
        p = p->next;
    }
}

// --- 主程序 [cite: 6-15] ---
int main() {
    LinkList L;
    int choice, i, y;
    ElemType e, t;
    LinkList res;

    InitList_L(L);

    do {
        cout << "\n      通讯录管理系统 (单链表版)\n"
             << "======================================\n"
             << "   0: 退出系统\n"
             << "   1: 插入新记录\n"
             << "   2: 删除指定记录\n"
             << "   3: 查询联系人\n"
             << "   4: 输出全部内容\n"
             << "======================================\n"
             << "请选择 (0-4): ";
        cin >> choice;

        switch (choice) {
            case 1:
                cout << "插入位置: ";
                cin >> i;
                inputOne(e);
                if (ListInsert_L(L, i, e))
                    cout << "插入成功。" << endl;
                else
                    cout << "位置非法。" << endl;
                break;
            case 2:
                cout << "删除位置: ";
                cin >> i;
                if (ListDelete_L(L, i, t)) {
                    cout << "已删除: " << t.name << endl;
                } else
                    cout << "删除失败。" << endl;
                break;
            case 3:
                cout << "31.姓名查询 32.学号查询: ";
                cin >> y;
                if (y == 31) {
                    cout << "查询姓名: ";
                    cin >> t.name;
                    res = LocateElem_L(L, t, fun1);
                } else {
                    cout << "查询学号: ";
                    cin >> t.num;
                    res = LocateElem_L(L, t, fun2);
                }
                if (res)
                    outputOne(res->data);
                else
                    cout << "未找到该记录。" << endl;
                break;
            case 4:
                output(L);
                break;
        }
    } while (choice != 0);

    // 释放整个链表空间
    LNode* p;
    while (L) {
        p = L;
        L = L->next;
        delete p;
    }

    return 0;
}