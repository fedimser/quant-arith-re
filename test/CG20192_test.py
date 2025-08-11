import pytest
from qsharp import init, eval
import random

import test_utils

@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 4, 8, 16, 32, 64, 80, 100])
def test_Multiply(n: int):
    op = "QuantumArithmetic.CG20192.Multiply"
    x, y, t = random.randint(0, 2**n - 1), random.randint(0, 2**n - 1), random.randint(0, 2**n - 1)
    ans = eval(f"{op}({n},{n},{t}L,{x}L,{y}L)")
    assert ans == x * y + t


@pytest.mark.parametrize("n", [3, 4, 8, 16, 32, 64, 80])
def test_ModExp(n: int):
    op = "QuantumArithmetic.CG20192.ModExpWindow(_,_,_,_,2,2)"
    N = 1+2*random.randint(1, 2**(n-1)-1)
    a = test_utils.random_coprime(N)
    x = random.randint(0, 2**n-1)
    ans = eval(f"TestUtils.TestModExp({n},{a}L,{x}L,{N}L,{op})")
    assert ans == test_utils.pow_mod(a, x, N)