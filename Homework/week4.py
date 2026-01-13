# -*- coding: gbk -*-
import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import make_blobs
from sklearn.preprocessing import StandardScaler

# 1. 生成实验数据：2维数据，100个样本，2个聚类中心
np.random.seed(42)  # 固定随机种子，保证结果可复现
X, y = make_blobs(n_samples=100, n_features=2, centers=2, random_state=42)

# 数据标准化（去中心化）
scaler = StandardScaler(with_std=False)  # 仅去中心化，不标准化方差
X_centered = scaler.fit_transform(X)

# 可视化原始数据
plt.figure(figsize=(8, 6))
plt.scatter(X_centered[:, 0], X_centered[:, 1], c=y, cmap='viridis', alpha=0.8)
plt.title('Oiginal')
plt.xlabel('1')
plt.ylabel('2')
plt.grid(True, alpha=0.3)
plt.show()
# 2. 计算协方差矩阵（对应数学步骤（2））
cov_matrix = np.cov(X_centered.T)  # 协方差矩阵：d×d（此处d=2）
print("cov_matrix：\n", cov_matrix)

# 3. 求解协方差矩阵的特征值和特征向量（对应数学步骤（3））
eigenvalues, eigenvectors = np.linalg.eig(cov_matrix)
print("\neigenvalues：", eigenvalues)
print("eigenvectors：\n", eigenvectors)

# 4. 按特征值从大到小排序特征向量（对应数学步骤（4））
# 得到特征值的排序索引（降序）
sorted_idx = np.argsort(eigenvalues)[::-1]
sorted_eigenvalues = eigenvalues[sorted_idx]
# 按排序索引重新排列特征向量
sorted_eigenvectors = eigenvectors[:, sorted_idx]

# 5. 选择前k个主成分（此处k=1，降维到1维）（对应数学步骤（5））
k = 1
W = sorted_eigenvectors[:, :k]  # 投影矩阵

# 6. 数据降维（对应数学步骤（6））
X_reduced = X_centered @ W  # 降维后的数据（100×1）

# 7. 可视化主成分方向和降维结果
plt.figure(figsize=(10, 7))

# 绘制去中心化数据
plt.scatter(X_centered[:, 0], X_centered[:, 1], c=y, cmap='viridis', alpha=0.8, label='Original')

# 绘制主成分（特征向量）方向
origin = [0], [0]  # 原点
plt.quiver(*origin, sorted_eigenvectors[0, 0], sorted_eigenvectors[1, 0], 
           color='red', scale=5, label='Biggest')
plt.quiver(*origin, sorted_eigenvectors[0, 1], sorted_eigenvectors[1, 1], 
           color='blue', scale=5, label='Smallest')

# 绘制降维后的数据投影回原空间的点
X_recovered = X_reduced @ W.T  # 将降维数据投影回原空间（用于可视化）
plt.scatter(X_recovered[:, 0], X_recovered[:, 1], c='black', marker='x', s=100, label='Processed')

plt.title("Freeman's Test")
plt.xlabel('1')
plt.ylabel('2')
plt.legend()
plt.grid(True, alpha=0.3)
plt.axis('equal')
plt.show()
total_variance = np.sum(np.var(X_centered, axis=0)) 
eigenvalues_sum = np.sum(sorted_eigenvalues)  
explained_variance_ratio = sorted_eigenvalues / eigenvalues_sum  
print(f"\nOriginal：{total_variance:.4f}")
print(f"eigenvalues_sum：{eigenvalues_sum:.4f}")
print(f"explained_variance_ratio[0]：{explained_variance_ratio[0]:.4f}")
print(f"explained_variance_ratio[1]：{explained_variance_ratio[1]:.4f}")
print(f"Processed：{np.sum(explained_variance_ratio[:k]):.4f}")
from sklearn.decomposition import PCA

# 使用sklearn的PCA
pca = PCA(n_components=k)
X_sklearn_reduced = pca.fit_transform(X_centered)

# 对比手动实现与sklearn的结果（符号可能相反，因为特征向量方向可正可负，不影响降维效果）
print("\nProcessed0：\n", X_reduced[:5].flatten())
print("PCA Processed0：\n", X_sklearn_reduced[:5].flatten())

# 验证特征值和主成分方向（sklearn的components_是特征向量的行）
print(f"\nPCA Processed1：{pca.explained_variance_}")
print(f"Processed1：{sorted_eigenvalues[:k]}")
print(f"\nPCA Processed2：{pca.components_}")
print(f"Processed2：{W.T}")
