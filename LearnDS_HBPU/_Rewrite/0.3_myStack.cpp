/*
 * @Date: 2026-05-18 17:16:12
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-05-28 10:18:14
 * @FilePath: /Code/LearnDS_HBPU/_Rewrite/0.3_myStack.cpp
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

int sizeArrayStack(ArrayStack* stack) { return stack->size; }

bool isEmptyArrayStack(ArrayStack* stack) { return stack->size == 0; }

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

int sizeLinkedListStack(LinkedListStack* s) { return s->size; }

bool isEmptyLinkedListStack(LinkedListStack* s) {
    return sizeLinkedListStack(s) == 0;
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
}

int main() {}