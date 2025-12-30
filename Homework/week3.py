import numpy as np
import matplotlib.pyplot as plt
C=np.array([[3,-2],
            [1,0]])
vals,vecs=np.linalg.eig(C)
#vals是特征值 vecs是特征向量
#eig是算特征值的函数 返回值有两个
print(vals)
print(vecs)
print("\n")
