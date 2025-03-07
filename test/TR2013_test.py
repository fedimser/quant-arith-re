import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("n", [1, 2, 3, 4, 5, 8, 16, 19])
def test_Add(n: int):
    op = "QuantumArithmetic.TR2013.Add"
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        ans = eval(f"TestUtils.BinaryOpInPlace({n},{a}L,{b}L,{op})")
        expected = (a + b) % (2**n)
        print(f"n:{n} - a:{a} - b:{b} - ans:{ans}")
        assert ans == expected


@pytest.mark.parametrize("n", [3, 4, 5, 8, 16])
def test_AddWithCarry(n: int):
    op = "QuantumArithmetic.TR2013.AddWithCarry"
    for _ in range(5):
        a = random.randint(0, 2**n - 1)
        b = random.randint(0, 2**n - 1)
        c = random.randint(0, 1)
        ans = eval(
            f"QuantumArithmetic.TR2013Test.BinaryOpInPlaceCarryIn({n},{a}L,{b}L,{c}L,{op})"
        )
        expected = (a + b + c) % (2**n)
        print(f"n:{n} - a:{a} - b:{b} - c:{c} - ans:{ans}")
        assert ans == expected
