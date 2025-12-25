#矩阵创建

import numpy as np
A=np.array([[1,2],[3,4]])
#创建矩阵
B=np.zeros((2,2))
#创建零矩阵
C=np.eye(2)
#创建单位矩阵
D=np.random.random((2,2))
#创建随机矩阵

#矩阵基本运算

E=A+C
#矩阵对应相加
print(E)
F=A*A
#矩阵对应相乘
print(F)
G=np.dot(A,A)
#矩阵点乘
print(G)
A_trans=A.T
#矩阵转置
H=A+A_trans
print(H)

#矩阵进阶

det=np.linalg.det(A)
print(det)
#行列式
inv_A=np.linalg.inv(A)
print(inv_A)
#逆矩阵
values,victors=np.linalg.eig(A)
print(values)
print(victors)
#特征值,特征向量
rank=np.linalg.matrix_rank(A)
print(rank)
#矩阵的轶

#矩阵形态变换

B=A.reshape(1,4)
print(B)
#改变维数但不改变数据
flat=A.flatten()
print(flat)
#将多维矩阵降为一维
B=[[4,3],[2,1]]
print(np.hstack((A,B)))
#水平堆叠
print(np.vstack((A,B)))
#垂直堆叠
