import pytest
from qsharp import init, eval
import random


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root='.')


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
@pytest.mark.parametrize("adder", [
    "Std.Arithmetic.RippleCarryTTKIncByLE",
    "Std.Arithmetic.RippleCarryCGIncByLE",
    "QuantumArithmetic.CDKM2004.Add",
    "QuantumArithmetic.DKRS2004.Add",
    "QuantumArithmetic.JHHA2016.Add_Mod2N",
])
@pytest.mark.parametrize("n", [2, 4, 8, 16])
def test_division(div_type: str, adder: str, n: int):
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder="+adder+"}"
    for _ in range(5):
        x, y = random.randint(0, 2**n-1), random.randint(1, 2**(n-1)-1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x//y
        assert r == x % y


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
def test_division_with_QFT_Adder(div_type: str):
    adder = "Std.Arithmetic.FourierTDIncByLE"
    n = 5
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder="+adder+"}"
    for _ in range(2):
        x, y = random.randint(0, 2**n-1), random.randint(1, 2**(n-1)-1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x//y
        assert r == x % y


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
def test_division_large(div_type: str):
    adder = "Std.Arithmetic.RippleCarryCGIncByLE"
    n = 100
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder="+adder+"}"
    for _ in range(5):
        x, y = random.randint(0, 2**n-1), random.randint(1, 2**(n-1)-1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x//y
        assert r == x % y


@pytest.mark.parametrize("n", [2, 3, 4, 8, 16, 32, 64, 77, 100])
def test_Divide(n: int):
    op = "QuantumArithmetic.TMVH2019.Divide"
    x, y = random.randint(0, 2**n-1), random.randint(1, 2**(n-1)-1)
    x1, y1, z1 = eval(f"TestUtils.TernaryOp({n},{n-1},{n},{x}L,{y}L,0L,{op})")
    assert (x1, y1, z1) == (x % y, y, x//y)
