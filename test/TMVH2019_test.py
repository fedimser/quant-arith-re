import pytest
from qsharp import init, eval
import random


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_Subtract(n: int):
    init(project_root='.')
    op ="QuantumArithmetic.TMVH2019.Subtract"
    for _ in range(10):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{x},{y},{op})")
        expected = (y-x) % (2**n)
        assert ans == expected


@pytest.mark.parametrize("op", ["Divide_Restoring", "Divide_NonRestoring"])
@pytest.mark.parametrize("n", [2, 3, 4])
def test_division_exhaustive(op: str, n: int):
    init(project_root='.')
    for x in range(0, 2**n):
        for y in range(1, 2**(n-1)):
            q, r = eval(f"QuantumArithmetic.TMVH2019Test.Test_{op}({n},{x},{y})")
            assert q == x//y
            assert r == x % y


@pytest.mark.parametrize("op", ["Divide_Restoring", "Divide_NonRestoring"])
@pytest.mark.parametrize("n", [8, 16, 24, 32, 63])
def test_division_random(op: str, n: int):
    init(project_root='.')
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        y = random.randint(1, 2**(n-1)-1)
        q, r = eval(f"QuantumArithmetic.TMVH2019Test.Test_{op}({n},{x},{y})")
        assert q == x//y
        assert r == x % y
