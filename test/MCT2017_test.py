import pytest
from qsharp import init, eval
import random

from superposition_test_utils import check_superposition_binary


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n1,n2", [
    (1, 1), (2, 2), (2, 16), (9, 2), (3, 3), (3, 4), (4, 4),
    (6, 8), (8, 8), (16, 16), (5, 16), (32, 32), (64, 64), (100, 100)
])
def test_Multiply(n1: int, n2: int):
    op = "QuantumArithmetic.MCT2017.Multiply"
    for _ in range(5):
        a = random.randint(0, 2**n1-1)
        b = random.randint(0, 2**n2-1)
        ans = eval(f"TestUtils.TestMultiply({n1},{n2},{a}L,{b}L,{op})")
        expected = a*b
        assert ans == expected



def test_superposition():
    op = "QuantumArithmetic.MCT2017.Multiply"
    check_superposition_binary([8, 8, 16], op, lambda x, y: x * y)
