import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root=".")

@pytest.mark.parametrize("n", [3, 4, 7, 8, 9, 11, 12])
def test_subtract_equal(n: int):
    op = "QuantumArithmetic.Yuan2022.Subtract_EqualBit"
    for _ in range(10):
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, 2**n - 1 if x > 2**n - 1 else x)
        ans = eval(f"TestUtils.Test_Subtract_Minuend({n},{y}L,{x}L,{op})")
        assert ans == (x - y) % (2**n)

@pytest.mark.parametrize("n", [3, 4, 7, 8, 9, 11, 12])
def test_subtract_unequal(n: int):
    op = "QuantumArithmetic.Yuan2022.Subtract_NotEqualBit"
    m = n - 1
    for _ in range(10):
        y = random.randint(0, 2**n - 1)
        x = random.randint(0, 2**m - 1 if y > 2**m - 1 else y)
        ans = eval(f"TestUtils.Test_Subtract_Minuend_Unequal({m},{x}L,{n},{y}L,{op})")
        assert ans == (y-x) % (2**n)
        
@pytest.mark.parametrize("n", [4, 6, 8, 16, 24, 32, 63])
def test_division(n: int):
    op = "QuantumArithmetic.Yuan2022.Divide"
    m = n // 2
    for _ in range(10):
        x = random.randint(2**m - 1, 2**n - 1)
        y = random.randint(2**(m-1), 2**m - 1)
        q, r = eval(f"TestUtils.Test_Divide_Unequal({n},{x},{m},{y},{op})")
        assert r == x % y
        assert q == x // y
