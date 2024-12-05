import pytest
from qsharp import init, eval
import random


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    init(project_root='.')
    op = "QuantumArithmetic.TR2009.Subtract"
    for _ in range(10):
        x = random.randint(0, 2**n - 1)
        y = random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x},{y},{op})")
        expected = (y-x) % (2**n)
        assert ans == expected
