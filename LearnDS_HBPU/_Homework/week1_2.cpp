#include <bits/stdc++.h>
using namespace std;

// 数据结构定义
typedef struct {
    int num;
    char name[20];
    char sex[3];
    char tel[14];
    char qq[12];
} ElemType;

typedef struct LNode {
    ElemType data;
    struct LNode* next;
} LNode, *LinkList;

// 初始化 [cite: 18]
void InitList_L(LinkList& L) {
    L = new LNode;
    L->next = NULL;
    cout << "链表初始化成功。" << endl;
}

// 插入 [cite: 18]
int ListInsert_L(LinkList& L, int i, ElemType e) {
    LNode* p = L;
    int j = 0;
    while (p && j < i - 1) {
        p = p->next;
        ++j;
    }
    if (!p || j > i - 1) return 0;
    LNode* s = new LNode;
    s->data = e;
    s->next = p->next;
    p->next = s;
    return 1;
}

// 删除 [cite: 18]
int ListDelete_L(LinkList& L, int i, ElemType& e) {
    LNode* p = L;
    int j = 0;
    while (p->next && j < i - 1) {
        p = p->next;
        ++j;
    }
    if (!(p->next) || j > i - 1) return 0;
    LNode* q = p->next;
    p->next = q->next;
    e = q->data;
    delete q;
    return 1;
}

// 查找 [cite: 18]
LinkList LocateElem_L(LinkList L, ElemType e, int (*op)(ElemType, ElemType)) {
    LNode* p = L->next;
    while (p) {
        if ((*op)(p->data, e)) return p;
        p = p->next;
    }
    return NULL;
}

// 通用函数复用
void inputOne(ElemType& x) {
    cout << "学号: ";
    cin >> x.num;
    cout << "姓名: ";
    cin >> x.name;
    cout << "性别: ";
    cin >> x.sex;
    cout << "电话: ";
    cin >> x.tel;
    cout << "QQ: ";
    cin >> x.qq;
}

int fun2(ElemType a, ElemType b) { return a.num == b.num; }

void output(LinkList L) {
    LNode* p = L->next;
    while (p) {
        printf("学号:%d | 姓名:%s\n", p->data.num, p->data.name);
        p = p->next;
    }
}

int main() {
    LinkList L;
    ElemType e, t;
    int choice, i;
    InitList_L(L);

    do {
        cout << "\n--- 单链表通讯录 ---\n0.退出 1.插入 2.删除 3.输出\n选择: ";
        cin >> choice;
        if (choice == 1) {
            cout << "位置: ";
            cin >> i;
            inputOne(e);
            ListInsert_L(L, i, e);
        } else if (choice == 2) {
            cout << "位置: ";
            cin >> i;
            if (ListDelete_L(L, i, t)) cout << "删除了: " << t.name << endl;
        } else if (choice == 3) {
            output(L);
        }
    } while (choice != 0);

    return 0;
}