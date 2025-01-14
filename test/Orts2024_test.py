import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root=".")

@pytest.mark.parametrize("n", [3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
def test_compare(n: int):
    op = "QuantumArithmetic.Orts2024.Subtract_NotEqualBit"
    m = n - 1
    for _ in range(20):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**m-1 if x > 2**m-1 else x)
        ans = eval(f"TestUtils.Test_Subtract_NotEqualBit({n},{x}L,{m},{y}L,{op})")
        assert ans == (x - y) % (2**n)
