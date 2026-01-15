import numpy as np
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Qt5Agg')
class Shape2D:
    # 创建一个Shape2D的类
    def __init__(self, points):
        # __init__是类名同名函数
        # self->指向当前对象的指针
        # points是形参
        self.original_points = points.T
        # 把转置之后的存入self中的op
        self.current_points = self.original_points.copy()
        # 把转置后的存入cp
    def translate(self, tx, ty):
        # 平移变换
        # X轴平移TX Y轴平移TY
        t_vec = np.array([[tx], [ty]])
        self.current_points = self.current_points + t_vec
        return self
    def scale(self, sx, sy):
        # 缩放变换
        # X轴缩放SX倍 Y轴缩放SY倍
        S = np.array([
            [sx, 0],
            [0, sy]
        ])
        self.current_points = np.dot(S, self.current_points)
        return self
    def rotate(self, degree):
        # 旋转变换
        theta = np.radians(degree)
        c, s = np.cos(theta), np.sin(theta)
        R = np.array([
            [c, -s],
            [s, c]
        ])
        self.current_points = np.dot(R, self.current_points)
        # 矩阵乘法实现旋转
        return self
    def reset(self):
        self.current_points = self.original_points.copy()
        return self
    def get_points_for_plot(self):
        p = self.current_points.T
        return np.vstack([p, p[0]])


# 初始化窗口
def setup_plot(ax, title):
    # ax是子窗口
    ax.set_title(title)
    # 这里的标题也可以改成 title
    ax.axhline(0, color='black', linewidth=1)
    ax.axvline(0, color='black', linewidth=1)
    # 画十字准心
    ax.grid(True, linestyle='--', alpha=0.5)
    # 打开网格
    ax.set_aspect('equal')
    # 强制显示像素相同
    ax.set_xlim(-2, 6)
    ax.set_ylim(-2, 6)
    # 锁定显示范围

# 渲染函数
def draw_shape(ax, shape, color, label, linestyle='-'):
    points = shape.get_points_for_plot()
    # 获取顶点数据
    ax.plot(points[:, 0], points[:, 1], c=color, lw=2, label=label, linestyle=linestyle)
    # 画线框
    # ​points[:, 0], points[:, 1]: 分别取出所有点的 X 坐标和 Y 坐标
    ax.fill(points[:, 0], points[:, 1], c=color, alpha=0.1)
    # 填充颜色
    ax.scatter(points[:, 0], points[:, 1], c=color, s=30)
    # 画顶点
    # ​s=30: 点的大小（Size）数值越大，图形每个角上的实心圆点就越明显


def main():
    # 定义
    raw_points = np.array([
        [0, 0],
        [3, 0],
        [2, 2]
    ])

    # 实例化
    shape = Shape2D(raw_points)
    # 申请显存
    # fig是整个大窗口 axes数组存了3个子窗口 figsize是number*100个像素
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    fig.canvas.manager.set_window_title("Android_Freeman's 2D Transformation Experiment")

    # Scaling
    ax1 = axes[0]
    setup_plot(ax1, "Freeman's Scaling Test")
    shape.reset()
    draw_shape(ax1, shape, 'gray', 'Original', '--')
    shape.scale(1.5, 1.5)
    draw_shape(ax1, shape, 'blue', 'Processed')
    ax1.legend()

    # Rotation
    ax2 = axes[1]
    setup_plot(ax2, "Freeman's Rotation Test")
    shape.reset()
    draw_shape(ax2, shape, 'gray', 'Original', '--')
    shape.rotate(90)
    draw_shape(ax2, shape, 'green', 'Processed')
    ax2.legend()

    # Combo
    ax3 = axes[2]
    setup_plot(ax3, "Freeman's Combo Test")
    shape.reset()
    draw_shape(ax3, shape, 'gray', 'Original', '--')
    shape.rotate(90).translate(5, 2)
    draw_shape(ax3, shape, 'red', 'Processed')
    ax3.legend()
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
