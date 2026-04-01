/*
 * @Date: 2026-03-30 17:14:28
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 18:15:56
 * @FilePath: /Code/LearnDS_HBPU/week1.cpp
 */
#include<bits/stdc++.h>
using namespace std;

const int ListInitSize = 100;
//开辟初始空间
const int ListIncrement = 10;
//开辟增量空间
const int BaseLine = 20;
//设置基准线

struct ElemType {
    int number;
    char name[BaseLine];
    char sex[BaseLine];
    char tel[BaseLine];
    char qq[BaseLine];
};

struct SqList {
    ElemType* elem;
    int length;
    //当前长度
    int list_size;
    //表长
};


bool InitList_Sq(SqList& List) {
//构造一个新表
    List.elem = new (nothrow) ElemType[ListInitSize];
    if (!List.elem) return false;
    //nothrow分配失败返回nullptr而不是崩溃

    List.length = 0;
    //当前表长为0
    List.list_size = ListInitSize;
    //表长为这个

    return true;
}

bool ListInsert_Sq(SqList& List, int index, ElemType elem) {
//来写个插入函数 需要操作的表 位置 数据元
    if (index < 1 || index > List.length + 1) return false;
    //下标越界

    if (List.length >= List.list_size) {
    //当前长度大于表长
        int newSize = List.list_size + ListIncrement;
        ElemType* newbase = new (nothrow) ElemType[newSize];
        if (!newbase) return false;
        //创建一个扩容后的新表

        for (int j = 0; j < List.length; j++) {
            newbase[j] = List.elem[j];
        }
        //移动数据元

        delete[] List.elem;
        //拆了旧表
        List.elem = newbase;
        //装了新表
        List.list_size = newSize;
        //还有新长度
    }

    for (int j = List.length - 1; j >= index - 1; j--) {
        List.elem[j + 1] = List.elem[j];
    }
    //总体往后面挪一格

    List.elem[index - 1] = elem;
    //空的位置塞进去
    List.length++;
    //长度加加
    return true;
}

bool ListDelete_Sq(SqList& List, int index, ElemType& elem) {
//来删个数据元
    if (index < 1 || index > List.length) return false;
    //经典下标越界
    elem = List.elem[index - 1];
    //删除之前给这个元素拿出来
    for (int j = index; j < List.length; j++) {
        List.elem[j - 1] = List.elem[j];
    }
    //直接覆盖过去
    List.length--;
    //长度减减
    return true;
}

int LocateElem_Sq(SqList List, ElemType elem, bool (*equal)(ElemType, ElemType)) {
    for (int i = 0; i < List.length; i++) {
        if (equal(List.elem[i], elem)) return i + 1;
    }
    return 0;
}

bool compareName(ElemType x, ElemType y) { 
    return strcmp(x.name, y.name) == 0; 
}

bool compareId(ElemType x, ElemType y) { 
    return x.number == y.number; 
}

void inputOne(ElemType& elem) {
    cin >> elem.number >> elem.name >> elem.sex >> elem.tel >> elem.qq;
}

void outputOne(ElemType elem) {
    cout << elem.number << "\t" << elem.name << "\t" << elem.sex << "\t" << elem.tel << "\t" << elem.qq << endl;
}

void output(SqList List) {
    for (int i = 0; i < List.length; i++) {
        outputOne(List.elem[i]);
    }
}

int main() {
    SqList List;
    int choice, index, m;
    ElemType elem, temp;

    InitList_Sq(List);

    do {
        cout << "1:Insert 2:Delete 3:Search 4:Output 0:Exit" << endl;
        cin >> choice;

        switch (choice) {
            case 1:
                cin >> index;
                inputOne(temp);
                ListInsert_Sq(List, index, temp);
                break;
            case 2:
                cin >> index;
                ListDelete_Sq(List, index, temp);
                break;
            case 3:
                int sub;
                cin >> sub;
                if (sub == 1) {
                    cin >> temp.name;
                    m = LocateElem_Sq(List, temp, compareName);
                } else {
                    cin >> temp.number;
                    m = LocateElem_Sq(List, temp, compareId);
                }
                if (m) outputOne(List.elem[m - 1]);
                break;
            case 4:
                output(List);
                break;
        }
    } while (choice != 0);

    delete[] List.elem;
    return 0;
}
