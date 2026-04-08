#include <bits/stdc++.h>
using namespace std;

#define LIST_INIT_SIZE 100
#define LISTINCREMENT 10

// 数据结构定义
typedef struct {
    int num;         // 学号
    char name[20];   // 姓名
    char sex[3];     // 性别
    char tel[14];    // 联系电话
    char qq[12];     // QQ号
} ElemType;

// 顺序表定义
typedef struct {
    ElemType *elem;  // 存储空间基地址
    int length;      // 当前长度
    int listsize;    // 当前分配的存储容量
} SqList;

// 构造一个空的线性表
int InitList_Sq(SqList &L) {
    L.elem = new ElemType[LIST_INIT_SIZE];
    if (!L.elem) exit(0);
    L.length = 0;
    L.listsize = LIST_INIT_SIZE;
    cout << "通讯录初始化成功。" << endl;
    return 1;
}

// 输入一条数据
void inputOne(ElemType &x) {
    cout << "学号: "; cin >> x.num;
    cout << "姓名: "; cin >> x.name;
    cout << "性别: "; cin >> x.sex;
    cout << "电话: "; cin >> x.tel;
    cout << "QQ: ";   cin >> x.qq;
}

// 输出一条数据
void outputOne(ElemType x) {
    printf("学号:%-8d | 姓名:%-10s | 性别:%-4s | 电话:%-12s | QQ:%-10s\n", 
           x.num, x.name, x.sex, x.tel, x.qq);
}

// 在顺序表L中第i个位置之前插入新的元素e
int ListInsert_Sq(SqList &L, int i, ElemType e) {
    if (i < 1 || i > L.length + 1) return 0;
    if (L.length >= L.listsize) {
        ElemType *newbase = (ElemType *)realloc(L.elem, (L.listsize + LISTINCREMENT) * sizeof(ElemType));
        if (!newbase) exit(0);
        L.elem = newbase;
        L.listsize += LISTINCREMENT;
    }
    ElemType *q = &(L.elem[i - 1]);
    for (ElemType *p = &(L.elem[L.length - 1]); p >= q; --p) *(p + 1) = *p;
    *q = e;
    ++L.length;
    return 1;
}

// 在顺序表L中删除第i个元素，并用e返回其值
int ListDelete_Sq(SqList &L, int i, ElemType &e) {
    if ((i < 1) || (i > L.length)) return 0;
    ElemType *p = &(L.elem[i - 1]);
    e = *p;
    ElemType *q = L.elem + L.length - 1;
    for (++p; p <= q; ++p) *(p - 1) = *p;
    --L.length;
    return 1;
}

// 比较函数
int fun1(ElemType x, ElemType y) { return strcmp(x.name, y.name) == 0; }
int fun2(ElemType x, ElemType y) { return x.num == y.num; }

// 查找元素
int LocateElem_Sq(SqList L, ElemType e, int (*equal)(ElemType, ElemType)) {
    for (int i = 0; i < L.length; i++) {
        if ((*equal)(L.elem[i], e)) return i + 1;
    }
    return 0;
}

void output(SqList L) {
    if (L.length == 0) cout << "通讯录为空。" << endl;
    for (int i = 0; i < L.length; i++) outputOne(L.elem[i]);
}

int main() {
    SqList L;
    int choice, i, y, m;
    ElemType e, t;
    L.elem = NULL;

    do {
        cout << "\n     通讯录管理系统(顺序表)\n";
        cout << "======================================\n";
        cout << "  0:退出 1:建立 2:插入 3:删除 4:查询 5:输出\n";
        cout << "======================================\n";
        cout << "请选择: ";
        cin >> choice;

        switch (choice) {
            case 1: InitList_Sq(L); break;
            case 2: 
                cout << "插入位置: "; cin >> i;
                inputOne(e);
                if(ListInsert_Sq(L, i, e)) cout << "成功。" << endl;
                break;
            case 3:
                cout << "删除位置: "; cin >> i;
                if(ListDelete_Sq(L, i, t)) cout << "已删除: " << t.name << endl;
                break;
            case 4:
                cout << "41.姓名查询 42.学号查询: "; cin >> y;
                if(y == 41) { cout << "姓名: "; cin >> t.name; m = LocateElem_Sq(L, t, fun1); }
                else { cout << "学号: "; cin >> t.num; m = LocateElem_Sq(L, t, fun2); }
                if(m) outputOne(L.elem[m-1]); else cout << "未找到。" << endl;
                break;
            case 5: output(L); break;
        }
    } while (choice != 0);

    if (L.elem) delete[] L.elem;
    return 0;
}