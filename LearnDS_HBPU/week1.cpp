/*
 * @Date: 2026-03-30 17:14:28
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-30 18:04:49
 * @FilePath: /Code/LearnDS_HBPU/week1.cpp
 */
#include<bits/stdc++.h>
using namespace std;

const int ListInitSize = 100;
const int ListIncrement = 10;
const int BaseLine = 20;

struct ElemType {
    int number;
    char name[BaseLine];
    char sex[10];
    char tel[15];
    char qq[15];
};

struct SqList {
    ElemType* elem;
    int length;
    int list_size;
};

bool InitList_Sq(SqList& List) {
    List.elem = new (nothrow) ElemType[ListInitSize];
    if (!List.elem) return false;
    List.length = 0;
    List.list_size = ListInitSize;
    return true;
}

bool ListInsert_Sq(SqList& List, int index, ElemType elem) {
    if (index < 1 || index > List.length + 1) return false;

    if (List.length >= List.list_size) {
        int newSize = List.list_size + ListIncrement;
        ElemType* newbase = new (nothrow) ElemType[newSize];
        if (!newbase) return false;

        for (int j = 0; j < List.length; j++) {
            newbase[j] = List.elem[j];
        }
        delete[] List.elem;
        List.elem = newbase;
        List.list_size = newSize;
    }

    for (int j = List.length - 1; j >= index - 1; j--) {
        List.elem[j + 1] = List.elem[j];
    }

    List.elem[index - 1] = elem;
    List.length++;
    return true;
}

bool ListDelete_Sq(SqList& List, int index, ElemType& elem) {
    if (index < 1 || index > List.length) return false;
    elem = List.elem[index - 1];
    for (int j = index; j < List.length; j++) {
        List.elem[j - 1] = List.elem[j];
    }
    List.length--;
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
