import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 63])
def test_Add(n: int):
    op = "QuantumArithmetic.DKRS2004.Add"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{a},{b},{op})")
        expected = (a+b) % (2**n)
        assert ans == expected



@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 31, 32, 62])
def test_AddWithCarry(n: int):
    op = "QuantumArithmetic.DKRS2004.AddWithCarry"
    for _ in range(5):
        a = random.randint(0, 2**n-1)
        b = random.randint(0, 2**n-1)
        ans = eval(f"TestUtils.BinaryOpInPlaceExtraOut({n},{a},{b},{op})")
        expected = a+b
        assert ans == expected
