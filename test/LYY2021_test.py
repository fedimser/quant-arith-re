import pytest
from qsharp import init, eval
import random

import test_utils


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


def test_AddConstant():
    n = 16
    for _ in range(5):
        x, y = random.randint(0, 2**n-1),  random.randint(0, 2**n-1)
        op = f"QuantumArithmetic.LYY2021.AddConstant({x}L,_)"
        ans = eval(f"TestUtils.UnaryOpInPlaceCtl({n},{y}L,{op})")
        assert ans == (x+y) % (2**n)


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModAdd(n: int):
    n = 16
    for _ in range(5):
        N = random.randint(2, 2**n-1)
        x, y = random.randint(0, N-1), random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModAdd(_,_,{N}L)"
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x}L,{y}L,{op})")
        assert ans == (x+y) % N


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModDbl(n: int):
    n = 16
    for _ in range(5):
        N = 1+2*random.randint(1, 2**(n-1)-1)
        x = random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModDbl(_,{N}L)"
        ans = eval(f"TestUtils.UnaryOpInPlaceCtl({n},{x}L,{op})")
        assert ans == (2*x) % N


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModMulFast(n: int):
    for _ in range(5):
        N = 1+2*random.randint(1, 2**(n-1)-1)
        x, y = random.randint(0, N-1), random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModMulFast(_,_,_,{N}L)"
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op})")
        assert ans == (x*y) % N


@pytest.mark.parametrize("n", [2, 3, 5, 10])
def test_ModMulByConstFast(n: int):
    for _ in range(5):
        N = 1+2*random.randint(1, 2**(n-1)-1)
        x, y = random.randint(0, N-1), random.randint(0, N-1)
        op = f"QuantumArithmetic.LYY2021.ModMulByConstFast(_,_,{x}L,{N}L)"
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{y}L,0L,{op})")
        assert ans == (x*y) % N


@pytest.mark.parametrize("op", [
    "QuantumArithmetic.LYY2021.ModExp",
    "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,_,_,1)",
    "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,_,_,3)",
    "QuantumArithmetic.LYY2021.ModExpWindowed(_,_,_,_,8)",
    "QuantumArithmetic.LYY2021.ModExpWindowedMontgomery(_,_,_,_,8)",
])
@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 7, 8, 9, 10, 16])
def test_ModExp(op: str, n: int):
    N = 1+2*random.randint(1, 2**(n-1)-1)
    a = test_utils.random_coprime(N)
    x = random.randint(0, 2**n-1)
    ans = eval(f"TestUtils.TestModExp({n},{a}L,{x}L,{N}L,{op})")
    assert ans == test_utils.pow_mod(a, x, N)


@pytest.mark.parametrize("m", [1, 2, 3, 4, 5])
def test_TableLookup(m: int):
    n = 8
    table = [random.randint(0, 2**n-1) for _ in range(2**m)]
    table_str = "["+",".join(f"{x}L" for x in table) + "]"
    ans = eval(
        f"QuantumArithmetic.LYY2021Test.TestTableLookup({n},{m},{table_str})")
    assert ans == table


@pytest.mark.parametrize("n", [2, 3, 4, 5, 6, 8, 11, 16])
def test_ModMulMontgomery(n: int):
    op = "QuantumArithmetic.LYY2021.ModMulMontgomery"
    for _ in range(10):
        N = 1+2*random.randint(1, 2**(n-1)-1)  # Odd number in [3..2^n-1].
        assert (3 <= N < 2**n and N % 2 == 1)
        K = test_utils.pow_mod((N+1)//2, n, N)  # 2^-n mod N.
        assert ((2**n)*K) % N == 1
        x = random.randint(0, 2**n-1)
        y = random.randint(0, N-1)
        ans = eval(f"TestUtils.BinaryOp({n},{x}L,{y}L,{op}(_,_,_,{N}L))")
        assert ans == (x*y*K) % N
