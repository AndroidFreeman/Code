from manim import *

class LinearAlgebraReport(Scene):
    def construct(self):
        # 1. 标题
        title = Text("线性变换的几何意义", font_size=40).to_edge(UP)
        self.add(title)

        # 2. 坐标系
        grid = NumberPlane()
        self.play(Create(grid), run_time=1.5)

        # 3. 原始向量
        v = Vector([1, 1], color=YELLOW)
        v_label = v.get_label("v = [1, 1]").scale(0.8)
        self.play(GrowArrow(v), Write(v_label))
        self.wait()

        # 4. 矩阵变换 A = [[1, 1], [0, 1]] (剪切)
        matrix = [[1, 1], [0, 1]]
        matrix_text = MathTex(r"A = \begin{bmatrix} 1 & 1 \\ 0 & 1 \end{bmatrix}").to_corner(UL)
        
        self.play(Write(matrix_text))
        self.play(
            grid.animate.apply_matrix(matrix),
            v.animate.apply_matrix(matrix),
            v_label.animate.move_to([2.2, 1.2, 0]), # 手动微调标签位置
            run_time=3
        )
        self.wait(2)
