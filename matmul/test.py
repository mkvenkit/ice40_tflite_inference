import numpy as np

def sum_sq(n):
    return (n*(n+1)*(2*n+1))/6

def test_matmul():
    """A x B"""  
    NROWS = 4
    NCOLS = 10
    A = np.zeros((NROWS, NCOLS))
    for i in range(NROWS):
        for j in range(NCOLS):
            A[i, j] = i+j;
    print(A)
    B = np.arange(NCOLS).reshape((NCOLS, 1))
    C = np.matmul(A, B)
    print(C)

def main():
    print("computing...")
    #print(sum_sq(70))
    test_matmul()

if __name__ == "__main__":
    main()