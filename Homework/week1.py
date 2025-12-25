import numpy as np
#Program1
A=np.array([[1,2],[3,4]])
B=np.eye(2)
print(A)
print(B)
B[0,1]=91
B[1,0]=69
print(B)

#Program2
A=np.array([[1,2],[3,4]])
B=np.eye(2)
C=A+B
D=A-B
print(C)
print(D)

#Prongram3
A=np.array([[1,2],[3,4]])
B=A*2
C=B/2
print(B)
print(C)

#Program4
A=np.array([[1,2],[3,4]])
B=np.eye(2)
B[0,1]=2
B[1,0]=3
C=A*B
D=A/B
print(C)
print(D)

#Program5
A=np.array([[1,2],[3,4]])
B=np.eye(2)
A_Trans=A.T
B_Trans=B.T
print(A_Trans)
print(B_Trans)

#Program6
A=np.array([[1,2],[3,4]])
B=np.eye(2)
C=np.linalg.inv(A)
D=np.linalg.inv(B)
print(C)
print(D)

#Program7
A_Rank=np.linalg.matrix_rank(A)
print(A_Rank)

