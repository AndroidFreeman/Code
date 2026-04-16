/*
 * @Date: 2026-04-13 17:15:20
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-16 11:30:41
 * @FilePath: /Code/LearnDS_HBPU/0.4_myQueue.cpp
 */
#include <bits/stdc++.h>
using namespace std;

const int MAX_QUEUE_SIZE = 100;
typedef char DataType;

struct ArrayQueue {
    DataType data[MAX_QUEUE_SIZE];
    int head;
    int tail;
    int count;
};

ArrayQueue* newArrayQueue() {
    ArrayQueue* q = new ArrayQueue;
    q->head = 0;
    q->tail = 0;
    q->count = 0;
    return q;
}

void delArrayQueue(ArrayQueue* q) { delete q; }

bool isEmptyArrayQueue(ArrayQueue* q) { return q->count == 0; }

bool pushArrayQueue(ArrayQueue* q, DataType x) {
    if (q->count == MAX_QUEUE_SIZE) {
        cout << "Error: ArrayQueue Overflow!" << endl;
        return false;
    }
    q->data[q->tail] = x;
    q->tail = (q->tail + 1) % MAX_QUEUE_SIZE;
    q->count++;
    return true;
}

bool popArrayQueue(ArrayQueue* q, DataType& val) {
    if (isEmptyArrayQueue(q)) {
        cout << "Error: ArrayQueue Empty!" << endl;
        return false;
    }
    val = q->data[q->head];
    q->head = (q->head + 1) % MAX_QUEUE_SIZE;
    q->count--;
    return true;
}

struct Node {
    DataType data;
    Node* next;
};

struct LinkedQueue {
    Node* front;
    Node* rear;
    int size;
};

LinkedQueue* newLinkedQueue() {
    LinkedQueue* q = new LinkedQueue;
    q->front = nullptr;
    q->rear = nullptr;
    q->size = 0;
    return q;
}

void delLinkedQueue(LinkedQueue* q) {
    while (q->front) {
        Node* tmp = q->front;
        q->front = q->front->next;
        delete tmp;
    }
    delete q;
}

bool isEmptyLinkedQueue(LinkedQueue* q) { return q->size == 0; }

void pushLinkedQueue(LinkedQueue* q, DataType x) {
    Node* newNode = new Node;
    newNode->data = x;
    newNode->next = nullptr;
    if (isEmptyLinkedQueue(q)) {
        q->front = q->rear = newNode;
    } else {
        q->rear->next = newNode;
        q->rear = newNode;
    }
    q->size++;
}

bool popLinkedQueue(LinkedQueue* q, DataType& val) {
    if (isEmptyLinkedQueue(q)) {
        cout << "Error: LinkedQueue Empty!" << endl;
        return false;
    }
    Node* tmp = q->front;
    val = tmp->data;
    q->front = q->front->next;
    if (q->front == nullptr) q->rear = nullptr;
    delete tmp;
    q->size--;
    return true;
}

int main() {
    int choice;
    DataType x, e;

    ArrayQueue* aq = newArrayQueue();
    LinkedQueue* lq = newLinkedQueue();

    do {
        cout << "\n--- Mixed Queue Manager ---" << endl;
        cout << "1: Push (Array) | 2: Pop (Array)" << endl;
        cout << "3: Push (Link)  | 4: Pop (Link)" << endl;
        cout << "0: Exit" << endl;
        cout << "Select: ";

        if (!(cin >> choice)) break;

        switch (choice) {
            case 1:
                cout << "Array Push: ";
                cin >> x;
                pushArrayQueue(aq, x);
                break;
            case 2:
                if (popArrayQueue(aq, e)) cout << "Array Popped: " << e << endl;
                break;
            case 3:
                cout << "Link Push: ";
                cin >> x;
                pushLinkedQueue(lq, x);
                break;
            case 4:
                if (popLinkedQueue(lq, e)) cout << "Link Popped: " << e << endl;
                break;
            case 0:
                break;
        }
    } while (choice != 0);

    delArrayQueue(aq);
    delLinkedQueue(lq);
    return 0;
}