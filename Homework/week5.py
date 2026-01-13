# -*- coding: gbk -*-
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
# 1. 读取图片并转为灰度图（请确保 test.jpg 在同一文件夹下，或修改为你的图片路径）
img = Image.open('test.jpg').convert('L')
img_matrix = np.array(img)
# 2. 展示原始图片
plt.figure(figsize=(6, 4))
plt.imshow(img_matrix, cmap='gray')
plt.title('Original Image')
plt.axis('off')
plt.show()
# 打印矩阵大小和奇异值信息
U, S, VT = np.linalg.svd(img_matrix)
#U-垂直方向 VT-竖直方向 S-奇异值
print(f"图像大小: {img_matrix.shape}")
print(f"奇异值总数: {len(S)}")
# 3. 定义压缩函数
def compress(matrix, k):
    u, s, vt = np.linalg.svd(matrix)
    # 只取前 k 个信息
    res = u[:, :k] @ np.diag(s[:k]) @ vt[:k, :]
    return res
# 4. 测试不同的压缩程度 (k值越小，图片越糊，文件越小)
ks = [10, 50, 100, 200]
plt.figure(figsize=(12, 10))
for i, k in enumerate(ks):
    recon_img = compress(img_matrix, k)
    plt.subplot(2, 2, i + 1)
    plt.imshow(recon_img, cmap='gray')
    plt.title(f'k = {k}')
    plt.axis('off')
plt.show()
