/*
 * @Date: 2026-04-09 10:29:53
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-13 17:12:37
 * @FilePath: /Code/LearnDS_HBPU/0.3_myStack.cpp
 */

#include <bits/stdc++.h>
using namespace std;

const long long MAX_SIZE = 10000;

struct ArrayStack {
    int* data;
    int size;
    int capacity;
};

ArrayStack* newArrayStack() {
    ArrayStack* stack = new ArrayStack;
    stack->data = new int[MAX_SIZE];
    stack->size = 0;
    stack->capacity = MAX_SIZE;
    return stack;
}

void delArrayStack(ArrayStack* stack) {
    delete[] stack->data;
    delete stack;
}

int sizeArrayStack(ArrayStack* stack) { 
    return stack->size; 
}

bool isEmptyArrayStack(ArrayStack* stack) {
     return stack->size == 0; 
}

void pushArrayStack(ArrayStack* stack, int num) {
    if (stack->size == MAX_SIZE) {
        cout << "Max";
        return;
    }
    stack->data[stack->size] = num;
    stack->size++;
}

int peekArrayStack(ArrayStack* stack) {
    if (stack->size == 0) {
        cout << "Empty";
        return INT_MIN;
    }
    return stack->data[stack->size - 1];
}

int popArrayStack(ArrayStack* stack) {
    int val = peekArrayStack(stack);
    stack->size--;
    return val;
}

struct ListNode {
    int data;
    ListNode* next;
};

struct LinkedListStack {
    ListNode* top;
    int size;
};

LinkedListStack* newLinkedListStack() {
    LinkedListStack* s = new LinkedListStack;
    s->top = nullptr;
    s->size = 0;
    return s;
}

void delLinkedListStack(LinkedListStack* s) {
    while (s->top) {
        ListNode* n = s->top->next;
        delete s->top;
        s->top = n;
    }
    delete s;
}

int sizeLinkdedListStack(LinkedListStack* s) { 
    return s->size; 
}

bool isEmptyLinkedListStack(LinkedListStack* s) { 
    return sizeLinkdedListStack(s) == 0; 
}

void pushLinkedListStack(LinkedListStack* s, int num) {
    ListNode* node = new ListNode;
    node->next = s->top;
    node->data = num;
    s->top = node;
    s->size++;
}

int peekLinkedListStack(LinkedListStack* s) {
    if (s->size == 0) {
        cout << "Empty";
        return INT_MAX;
    }
    return s->top->data;
}

int popLinkedListStack(LinkedListStack* s) {
    int data = peekLinkedListStack(s);
    ListNode* tmp = s->top;
    s->top = s->top->next;
    delete tmp;
    s->size--;
    return data;
}

void change(int num) {
    if (num == 0) {
        cout << "0" << endl;
        return;
    }
    ArrayStack* s = newArrayStack();
    int temp = num;
    while (temp > 0) {
        pushArrayStack(s, temp % 2);
        temp /= 2;
    }
    cout << num << "Bin: ";
    while (!isEmptyArrayStack(s)) {
        cout << popArrayStack(s);
    }
    cout << endl;
    delArrayStack(s);
}

int main() {
    int choice;
    int x, e;
    ArrayStack* s = newArrayStack();

    do {
        printf("===============================\n");
        printf("           0:退出\n");
        printf("           1:初始化栈\n");
        printf("           2:入栈\n");
        printf("           3:出栈\n");
        printf("           4:读取栈顶元素\n");
        printf("           5:进制转换(任务二)\n");
        printf("===============================\n");
        printf("输入操作选择代码(0-5):");
        
        if (scanf("%d", &choice) != 1) break;

        while (choice < 0 || choice > 5) {
            printf("输入有误，请重新输入(0-5):");
            scanf("%d", &choice);
        }

        switch (choice) {
            case 0:
                delArrayStack(s);
                exit(0);
            case 1:
                delArrayStack(s);
                s = newArrayStack();
                printf("栈已初始化\n");
                break;
            case 2:
                printf("请输入要入栈的整数值:");
                scanf("%d", &x);
                pushArrayStack(s, x);
                break;
            case 3:
                if (isEmptyArrayStack(s)) {
                    printf("栈为空，无法出栈\n");
                } else {
                    e = popArrayStack(s);
                    printf("出栈元素的值是:%d\n", e);
                }
                break;
            case 4:
                e = peekArrayStack(s);
                if (e != INT_MIN) {
                    printf("栈顶元素的值是:%d\n", e);
                }
                break;
            case 5:
                printf("请输入要转换的十进制数:");
                scanf("%d", &x);
                change(x);
                break;
        }
    } while (choice != 0);
    return 0;
}
