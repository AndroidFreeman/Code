/*
 * @Date: 2026-03-17 13:02:25
 * @Github: https://github.com/AndroidFreeman
 * BTW, I use Arch 
 * @Author: Android_Freeman
 * @LastEditTime: 2026-03-17 13:11:03
 * @FilePath: /Code_Sync/CompilerTest/Mini_Compiler.c
 */
 

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// 定义逻辑操作符
typedef enum { OP_AND, OP_OR, OP_NOT, OP_VAR } OpType;

typedef struct LNode {
    OpType type;
    char var_name;
    struct LNode *l, *r;
} LNode;

// 创建逻辑节点的助手函数
LNode* new_node(OpType t, LNode* l, LNode* r) {
    LNode* n = malloc(sizeof(LNode));
    n->type = t; n->l = l; n->r = r;
    return n;
}

LNode* new_var(char name) {
    LNode* n = malloc(sizeof(LNode));
    n->type = OP_VAR; n->var_name = name; n->l = n->r = NULL;
    return n;
}

// --- 数理逻辑应用：双重否定律 !(!P) -> P ---
LNode* optimize(LNode* n) {
    if (!n) return NULL;
    // 递归优化子树
    n->l = optimize(n->l);
    n->r = optimize(n->r);

    // 应用数理逻辑规则：¬(¬P) ≡ P
    if (n->type == OP_NOT && n->l && n->l->type == OP_NOT) {
        printf("  [Logic Opt]: Applying Double Negation Law ¬(¬%c) => %c\n", 
               n->l->l->var_name, n->l->l->var_name);
        LNode* optimized = n->l->l;
        free(n->l); free(n); // 释放无用节点
        return optimized;
    }
    return n;
}

// --- 后端：生成汇编代码 ---
void emit_asm(LNode* n) {
    if (n->type == OP_VAR) {
        printf("  cmp byte [%c], 0\n", n->var_name);
        return;
    }
    if (n->type == OP_NOT) {
        emit_asm(n->l);
        printf("  setz al\n"); // 如果为0则置1 (逻辑非)
        return;
    }
    // 处理 AND/OR 涉及条件跳转，此处简化示意
    if (n->type == OP_AND) {
        emit_asm(n->l);
        printf("  jz .FALSE_LABEL\n");
        emit_asm(n->r);
    }
}

int main() {
    // 模拟编译：if ( !!a )
    // 这是一个典型的 .c 语句
    printf("Compiling .c logic: if ( !!a ) ...\n\n");

    // 1. 词法/语法分析构建的原始 AST: NOT(NOT(VAR('a')))
    LNode* root = new_node(OP_NOT, new_node(OP_NOT, new_var('a'), NULL), NULL);

    // 2. 语义分析/优化阶段：应用数理逻辑
    printf("--- Optimization Phase ---\n");
    root = optimize(root);

    // 3. 代码生成阶段：生成汇编
    printf("\n--- Generated x86 Assembly ---\n");
    emit_asm(root);
    printf("  jnz .TRUE_LABEL\n");

    return 0;
}