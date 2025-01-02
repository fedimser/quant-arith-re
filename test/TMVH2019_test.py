import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
@pytest.mark.parametrize("adder", [
    "Std.Arithmetic.RippleCarryTTKIncByLE",
    "Std.Arithmetic.RippleCarryCGIncByLE"
])
@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_division(div_type: str, adder: str, n: int):
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder="+adder+"}"
    for _ in range(5):
        x, y = random.randint(0, 2**n-1), random.randint(1, 2**(n-1)-1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x//y
        assert r == x % y
