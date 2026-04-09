/*
 * @Date: 2026-04-09 10:29:53
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-09 11:29:34
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

int main() {
    cout << "--- ArrayStack Test ---" << endl;
    ArrayStack* as = newArrayStack();
    pushArrayStack(as, 100);
    pushArrayStack(as, 200);
    pushArrayStack(as, 300);

    cout << "ArrayStack Size: " << sizeArrayStack(as) << endl;
    cout << "ArrayStack Peek: " << peekArrayStack(as) << endl;
    cout << "ArrayStack Pop: " << popArrayStack(as) << endl;
    cout << "ArrayStack Pop: " << popArrayStack(as) << endl;
    
    delArrayStack(as);
    cout << "ArrayStack memory cleared." << endl << endl;


    cout << "--- LinkedListStack Test ---" << endl;
    LinkedListStack* ls = newLinkedListStack();
    pushLinkedListStack(ls, 10);
    pushLinkedListStack(ls, 20);
    pushLinkedListStack(ls, 30);

    cout << "LinkedListStack Size: " << sizeLinkdedListStack(ls) << endl;
    cout << "LinkedListStack Peek: " << peekLinkedListStack(ls) << endl;
    cout << "LinkedListStack Pop: " << popLinkedListStack(ls) << endl;
    cout << "LinkedListStack Pop: " << popLinkedListStack(ls) << endl;

    delLinkedListStack(ls);
    cout << "LinkedListStack memory cleared." << endl;

    return 0;
}
