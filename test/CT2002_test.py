import pytest
from qsharp import init, eval
import random

@pytest.mark.parametrize("n", [2, 8, 16, 32, 63])
def test_Add(n: int):
    op = "QuantumArithmetic.CT2002.Add"
    init(project_root='.')
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x},{y},{op})")
        assert ans == (x+y) % (2**n)


@pytest.mark.parametrize("n", [2, 8, 16, 32, 63])
def test_Subtract(n: int):
    init(project_root='.')
    op = "QuantumArithmetic.CT2002.Subtract"
    for _ in range(10):
        x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x},{y},{op})")
        assert ans == (x-y) % (2**n)
