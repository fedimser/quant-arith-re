"""Functional tests for addition algorihtms."""

import pytest
from qsharp import init, eval
import random


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_addition_random(n: int):
    init(project_root='.')
    op = "QuantumArithmetic.Add_RippleCarryTTK"
    for _ in range(10):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**n-1)
        ans = eval(f"""
            QuantumArithmetic.Test.PerformArithmeticOperationInPlace({n},{n},{x},{y},{op})
        """)
        expected = (x+y) % (2**n)
        assert ans == expected


@pytest.mark.parametrize("n", [2, 3, 5, 8, 16, 32, 63])
def test_subtraction(n: int):
    init(project_root='.')
    op = "QuantumArithmetic.Subtract"
    for _ in range(10):
        x = random.randint(0, 2**n-1)
        y = random.randint(0, 2**n-1)
        ans = eval(f"""
            QuantumArithmetic.Test.PerformArithmeticOperationInPlace({n},{n},{x},{y},{op})
        """)
        expected = (y-x) % (2**n)
        assert ans == expected


@pytest.mark.parametrize("op", ["Divide_TMVH_Restoring", "Divide_TMVH_NonRestoring"])
@pytest.mark.parametrize("n", [2, 3, 4, 5])
def test_division_exhaustive(op: str, n: int):
    init(project_root='.')
    for x in range(0, 2**n):
        for y in range(1, 2**(n-1)):
            q, r = eval(f"QuantumArithmetic.Test.Test_{op}({n},{x},{y})")
            assert q == x//y
            assert r == x % y


@pytest.mark.parametrize("op", ["Divide_TMVH_Restoring", "Divide_TMVH_NonRestoring"])
@pytest.mark.parametrize("n", [8, 16, 24, 32, 63])
def test_division_random(op: str, n: int):
    init(project_root='.')
    for _ in range(5):
        x = random.randint(0, 2**n-1)
        y = random.randint(1, 2**(n-1)-1)
        q, r = eval(f"QuantumArithmetic.Test.Test_{op}({n},{x},{y})")
        assert q == x//y
        assert r == x % y
