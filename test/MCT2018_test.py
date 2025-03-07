import pytest
from qsharp import init, eval
import random
import math


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 6, 7, 8])
def test_SquareRoot_Exhaustive(n: int):
    op = "QuantumArithmetic.MCT2018.SquareRoot"
    for x in range(2**n):
        ans = eval(f"TestUtils.BinaryOpArb({n},{n},{x}L,0L,{op})")
        true_root = math.floor(math.sqrt(x))
        expected = (x - true_root**2), true_root
        assert ans == expected


@pytest.mark.parametrize("n1,n2", [
    (2, 1), (2, 3), (5, 3), (5, 10), (10, 5), (10, 6), (10, 11), (16, 8),
    (32, 16), (32, 32), (64, 32), (100, 50)])
def test_SquareRoot(n1: int, n2: int):
    op = "QuantumArithmetic.MCT2018.SquareRoot"
    for _ in range(5):
        x = random.randint(0, 2**n1-1)
        ans = eval(f"TestUtils.BinaryOpArb({n1},{n2},{x}L,0L,{op})")
        true_root = math.isqrt(x)
        expected = (x - true_root**2), true_root
        assert ans == expected
