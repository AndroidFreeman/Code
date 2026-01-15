import numpy as np
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Qt5Agg')
def solve_linear_system():
    # 注意：函数内部的代码必须缩进
    print("Solving...")
    A = np.array([[2, 3], [5, -2]], dtype=np.float64)
    b = np.array([8, 1], dtype=np.float64)
    # Solve
    result = np.linalg.solve(A, b)
    x_val = result[0]
    y_val = result[1]
    print(f"Solve: x={x_val:.4f}, y={y_val:.4f}")

def linear_fitting():
    print("Fitting...")
    # Prepare
    np.random.seed(42) # 设置随机种子
    x = np.linspace(0, 10, 50) # X轴数据
    y_true = 2 * x + 1 # 真实的Y
    # np.random.normal(均值，标准差(混乱程度)，形状)
    noise = np.random.normal(0, 0.8, size=x.shape)
    y_noisy = y_true + noise # 加入高斯噪声
    # 最小二乘 手动拟合
    m = len(x)
    sum_x = np.sum(x)
    sum_x2 = np.sum(x**2)
    sum_y = np.sum(y_noisy)
    sum_xy = np.sum(x * y_noisy)
    # 系数矩阵
    matrix_left = np.array([
        [sum_x2, sum_x],
        [sum_x, m]
    ])
    # 常数项
    vector_right = np.array([sum_xy, sum_y])
    # 求解
    params = np.linalg.solve(matrix_left, vector_right)
    k_manual, b_manual = params
    y_fit_manual = k_manual * x + b_manual
    # 库函数对比
    params_poly = np.polyfit(x, y_noisy, 1)
    k_poly, b_poly = params_poly
    y_fit_poly = k_poly * x + b_poly
    print("The original: y=2x+1")
    print(f"Manual: y={k_manual:.4f}x+{b_manual:.4f}")
    print(f"Poly: y={k_poly:.4f}x+{b_poly:.4f}")
    # 绘图
    plt.scatter(x, y_noisy, color='red', alpha=0.5, label='Noisy') # 散点图
    plt.plot(x, y_true, color='green', linewidth=2, label='Real')
    plt.plot(x, y_fit_manual, color='blue', linestyle='--', linewidth=2, label='Manual')
    plt.xlabel('X')
    plt.ylabel('Y')
    plt.title("Freeman's Test")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.show()

if __name__ == '__main__':
    solve_linear_system()
    linear_fitting()
