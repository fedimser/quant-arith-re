import random

import pytest

from test_utils import ArithmeticOpTester, eval_qsharp, run_unary_op


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddMod2NMinus1OutOfPlace(n: int):
    MOD = 2**n - 1
    op = "QuantumArithmetic.NZLS2023.AddMod2NMinus1OutOfPlace"
    tester = ArithmeticOpTester(op, [n, n, n])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        assert tester.run([a, b, 0])[2] % MOD == (a + b) % MOD


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddMod2NMinus1InPlace(n: int):
    MOD = 2**n - 1
    op = "QuantumArithmetic.NZLS2023.AddMod2NMinus1InPlace"
    tester = ArithmeticOpTester(op, [n, n])
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        assert tester.run([a, b])[1] % MOD == (a + b) % MOD


@pytest.mark.parametrize("n", [2, 4, 6, 8, 16, 32, 64])
def test_CyclicShiftRight(n: int):
    for _ in range(1):
        x = random.randint(0, 2**n - 1)
        r = random.randint(-n, n)
        op = f"QuantumArithmetic.NZLS2023.CyclicShiftRight(_,{r})"
        ans = run_unary_op(op, n, x)
        r1 = r % n
        expected = (x >> (n - r1)) + ((x % (2 ** (n - r1))) << r1)
        assert ans == expected


@pytest.mark.parametrize("n", [2, 4, 6, 8, 16])
def test_Butterfly(n: int):
    assert n % 2 == 0
    N = 2 ** (n // 2) + 1  # modulo.
    for _ in range(1):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        op = "QuantumArithmetic.NZLS2023Test.TestButterfly"
        ans1, ans2 = eval_qsharp(f"{op}({n},{a}L,{b}L)")
        print("N=", N)
        assert ans1 % N == (a + b) % N
        assert ans2 % N == (a - b) % N


def test_FFT():
    n1, M1, D = 48, 3, 16
    N = 2**n1 + 1
    g = 2 ** (2 * M1)
    for _ in range(1):
        input = [random.randint(0, N - 1) for _ in range(D)]
        op = "QuantumArithmetic.NZLS2023Test.TestFFT"
        input_str = "[" + ",".join(f"{x}L" for x in input) + "]"
        ans = eval_qsharp(f"{op}({n1},{M1},{input_str})")
        expected = [
            sum(input[t] * g ** (t * m) for t in range(D)) % N for m in range(D)
        ]
        for i in range(D):
            assert ans[i] % N == expected[i] % N
