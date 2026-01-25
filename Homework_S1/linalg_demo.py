from manim import *

class LinearAlgebraReport(Scene):
    def construct(self):
        plane = NumberPlane()
        self.add(plane)
        
        # 矩阵 A = [[1, 1], [0, 1]] (剪切变换)
        matrix = [[1, 1], [0, 1]]
        
        # 定义基向量
        i_hat = Vector([1, 0], color=GREEN)
        j_hat = Vector([0, 1], color=RED)
        
        self.play(Create(i_hat), Create(j_hat))
        self.wait()
        
        # 演示空间重塑
        self.play(
            plane.animate.apply_matrix(matrix),
            i_hat.animate.apply_matrix(matrix),
            j_hat.animate.apply_matrix(matrix),
            run_time=2
        )
        self.wait()
