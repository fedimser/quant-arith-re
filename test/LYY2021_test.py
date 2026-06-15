import random

import pytest

import test_utils
from test_utils import ArithmeticOpTester, run_unary_op


def test_AddConstant():
    n = 16
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
        op = f"QuantumArithmetic.LYY2021.AddConstant({x}L,_)"
        assert run_unary_op(op, n, y) == (x + y) % (2**n)


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModAdd(n: int):
    n = 16
    tester_cache = {}
    for _ in range(5):
        N = random.randint(2, 2**n - 1)
        x, y = random.randint(0, N - 1), random.randint(0, N - 1)
        op = f"QuantumArithmetic.LYY2021.ModAdd(_,_,{N}L)"
        tester = tester_cache.setdefault(op, ArithmeticOpTester(op, [n, n]))
        assert tester.run([x, y]) == [x, (x + y) % N]


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModDbl(n: int):
    n = 16
    for _ in range(5):
        N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)
        x = random.randint(0, N - 1)
        op = f"QuantumArithmetic.LYY2021.ModDbl(_,{N}L)"
        assert run_unary_op(op, n, x) == (2 * x) % N


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModMulFast(n: int):
    tester_cache = {}
    for _ in range(5):
        N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)
        x, y = random.randint(0, N - 1), random.randint(0, N - 1)
        op = f"QuantumArithmetic.LYY2021.ModMulFast(_,_,_,{N}L)"
        tester = tester_cache.setdefault(op, ArithmeticOpTester(op, [n, n, n]))
        assert tester.run([x, y, 0]) == [x, y, (x * y) % N]


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModMulByConstFast(n: int):
    tester_cache = {}
    for _ in range(5):
        N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)
        x, y = random.randint(0, N - 1), random.randint(0, N - 1)
        op = f"QuantumArithmetic.LYY2021.ModMulByConstFast(_,_,{x}L,{N}L)"
        tester = tester_cache.setdefault(op, ArithmeticOpTester(op, [n, n]))
        assert tester.run([y, 0]) == [y, (x * y) % N]


@pytest.mark.parametrize(
    "op",
    [
        "QuantumArithmetic.LYY2021.ModExp(_,_,{a}L,{N}L)",
        "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,{a}L,{N}L,1)",
        "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,{a}L,{N}L,3)",
        "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,{a}L,{N}L,8)",
        "QuantumArithmetic.LYY2021.ModExpWindowedMontgomery(_,_,{a}L,{N}L,8)",
    ],
)
@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 7, 8, 9, 10, 16])
def test_ModExp(op: str, n: int):
    N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)
    a = test_utils.random_coprime(N)
    x = random.randint(0, 2**n - 1)
    tester = ArithmeticOpTester(op.format(a=a, N=N), [n, n])
    assert tester.run([x, 0]) == [x, pow(a, x, mod=N)]


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 8, 11, 16])
def test_ModMulMontgomery(n: int):
    op = "QuantumArithmetic.LYY2021.ModMulMontgomery"
    for _ in range(10):
        N = 1 + 2 * random.randint(1, 2 ** (n - 1) - 1)  # Odd number in [3..2^n-1].
        assert 3 <= N < 2**n and N % 2 == 1
        K = pow((N + 1) // 2, n, mod=N)  # 2^-n mod N.
        assert ((2**n) * K) % N == 1
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, N - 1)
        op_n = f"{op}(_,_,_,{N}L)"
        tester = ArithmeticOpTester(op_n, [n, n, n])
        assert tester.run([x, y, 0]) == [x, y, (x * y * K) % N]
