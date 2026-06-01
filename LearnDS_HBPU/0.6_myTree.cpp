/*
 * @datetime: 2026-06-02 01:03:22
 * @Github: https://github.com/AndroidFreeman
 * @Author: Android_Freeman
 * @relativePath: /Code/LearnDS_HBPU/0.6_myTree.cpp
 * @Description:
 */
/*
 * @Date: 2026-05-28 10:20:36
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-06-01 17:28:10
 * @FilePath: /Code/LearnDS_HBPU/0.6_myTree.cpp
 */

#include<bits/stdc++.h>
using namespace std;

struct TreeNode{
    int val;
    TreeNode* left;
    TreeNode* right;
    TreeNode(int x):val(x),left(nullptr),right(nullptr){}
};

void preOrder(TreeNode* root){
    if(root==nullptr) return;
    cout<<root->val<<" ";
    preOrder(root->left);
    preOrder(root->right);
}

void inOrder(TreeNode* root){
    if(root==nullptr) return;
    inOrder(root->left);
    cout<<root->val<<" ";
    inOrder(root->right);
}

void postOrder(TreeNode* root){
    if(root==nullptr) return;
    postOrder(root->left);
    postOrder(root->right);
    cout<<root->val<<" ";
}

void freeTree(TreeNode* root){
    if(root==nullptr) return;
    freeTree(root->left);
    freeTree(root->right);
    delete root;
}

int main() {
    // 手动手动构建一个简单的二叉树:
    //        1
    //       / \
    //      2   3
    //     /
    //    4

    TreeNode* root = new TreeNode(1);
    // root->left = new TreeNode(2);
    // root->right = new TreeNode(3);
    // root->left->left = new TreeNode(4);
    root->right=new TreeNode(2);
    root->right->left=new TreeNode(3);
    root->right->right=new TreeNode(4);
    root->right->right->left=new TreeNode(5);
    root->right->right->right=new TreeNode(6);
    root->right->right->right->left=new TreeNode(7);

    // 测试三种遍历
    std::cout << "前序遍历: ";
    preOrder(root);
    std::cout << std::endl;

    std::cout << "中序遍历: ";
    inOrder(root);
    std::cout << std::endl;

    std::cout << "后序遍历: ";
    postOrder(root);
    std::cout << std::endl;

    // 清理内存
    freeTree(root);

    return 0;
}
