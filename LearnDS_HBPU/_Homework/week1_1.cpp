#include <bits/stdc++.h>

using namespace std;

// 数据结构定义
struct ElemType {
    int num;        // 学号
    char name[20];  // 姓名
    char sex[3];    // 性别
    char tel[14];   // 联系电话
    char qq[12];    // QQ号
};

struct SqList {
    ElemType* elem;  // 存储空间基地址
    int length;      // 当前长度
    int listsize;    // 当前分配的存储容量
};

const int LIST_INIT_SIZE = 100;
const int LISTINCREMENT = 10;

// --- 函数实现 ---

// 构造一个空的线性表
int InitList_Sq(SqList& L) {
    L.elem = new (nothrow) ElemType[LIST_INIT_SIZE];
    if (!L.elem) return 0;
    L.length = 0;
    L.listsize = LIST_INIT_SIZE;
    cout << "通讯录初始化成功。" << endl;
    return 1;
}

// 输入一条数据
void inputOne(ElemType& x) {
    cout << "请输入学号、姓名、性别、电话、QQ（空格隔开）: ";
    cin >> x.num >> x.name >> x.sex >> x.tel >> x.qq;
}

// 输出一条数据
void outputOne(ElemType x) {
    cout << left << setw(10) << x.num << setw(10) << x.name << setw(6) << x.sex
         << setw(15) << x.tel << setw(12) << x.qq << endl;
}

// 输出顺序表
void output(SqList L) {
    if (L.length == 0) {
        cout << "通讯录目前为空。" << endl;
        return;
    }
    cout << left << setw(10) << "学号" << setw(10) << "姓名" << setw(6)
         << "性别" << setw(15) << "手机号" << setw(12) << "QQ号" << endl;
    cout << string(53, '-') << endl;
    for (int i = 0; i < L.length; i++) {
        outputOne(L.elem[i]);
    }
}

// 插入功能
int ListInsert_Sq(SqList& L, int i, ElemType e) {
    if (i < 1 || i > L.length + 1) return 0;
    if (L.length >= L.listsize) {
        ElemType* newbase = new (nothrow) ElemType[L.listsize + LISTINCREMENT];
        if (!newbase) return 0;
        memcpy(newbase, L.elem, L.length * sizeof(ElemType));
        delete[] L.elem;
        L.elem = newbase;
        L.listsize += LISTINCREMENT;
    }
    for (int j = L.length - 1; j >= i - 1; j--) {
        L.elem[j + 1] = L.elem[j];
    }
    L.elem[i - 1] = e;
    ++L.length;
    return 1;
}

// 删除功能
int ListDelete_Sq(SqList& L, int i, ElemType& e) {
    if (i < 1 || i > L.length) return 0;
    e = L.elem[i - 1];
    for (int j = i; j < L.length; j++) {
        L.elem[j - 1] = L.elem[j];
    }
    --L.length;
    return 1;
}

// 比较函数
int fun1(ElemType x, ElemType y) { return strcmp(x.name, y.name) == 0; }
int fun2(ElemType x, ElemType y) { return x.num == y.num; }

// 查找功能
int LocateElem_Sq(SqList L, ElemType e, int (*equal)(ElemType, ElemType)) {
    for (int i = 0; i < L.length; i++) {
        if ((*equal)(L.elem[i], e)) return i + 1;
    }
    return 0;
}

// --- 主程序 ---
int main() {
    SqList L;
    int choice, i, y, m;
    ElemType e, t;
    L.elem = nullptr;

    do {
        cout << "\n      通讯录管理系统 (顺序表版)\n"
             << "======================================\n"
             << "   0: 退出系统\n"
             << "   1: 建立/初始化通讯录\n"
             << "   2: 插入新记录\n"
             << "   3: 删除指定记录\n"
             << "   4: 查询联系人\n"
             << "   5: 输出全部内容\n"
             << "======================================\n"
             << "请选择 (0-5): ";
        cin >> choice;

        switch (choice) {
            case 1:
                InitList_Sq(L);
                break;
            case 2:
                cout << "输入插入位置 i: ";
                cin >> i;
                inputOne(e);
                if (ListInsert_Sq(L, i, e))
                    cout << "插入成功。" << endl;
                else
                    cout << "插入失败，位置不合法。" << endl;
                break;
            case 3:
                cout << "输入要删除的位置 i: ";
                cin >> i;
                if (ListDelete_Sq(L, i, t)) {
                    cout << "已删除记录：" << t.name << endl;
                } else
                    cout << "删除失败。" << endl;
                break;
            case 4:
                cout << "41.按姓名查询  42.按学号查询\n选择选项: ";
                cin >> y;
                if (y == 41) {
                    cout << "需查询姓名: ";
                    cin >> t.name;
                    m = LocateElem_Sq(L, t, fun1);
                } else {
                    cout << "需查询学号: ";
                    cin >> t.num;
                    m = LocateElem_Sq(L, t, fun2);
                }
                if (m)
                    outputOne(L.elem[m - 1]);
                else
                    cout << "查询失败，未找到该记录。" << endl;
                break;
            case 5:
                output(L);
                break;
        }
    } while (choice != 0);

    if (L.elem) delete[] L.elem;
    return 0;
}