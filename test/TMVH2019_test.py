import pytest
from qsharp import init, eval
import random

from superposition_test_utils import (
    IntSuperposition,
    read_superposition,
    apply_binary_op,
)


@pytest.fixture(scope="session", autouse=True)
def setup():
    init(project_root="./lib/")


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
@pytest.mark.parametrize(
    "adder",
    [
        "Std.Arithmetic.RippleCarryTTKIncByLE",
        "Std.Arithmetic.RippleCarryCGIncByLE",
        "QuantumArithmetic.CDKM2004.Add",
        "QuantumArithmetic.DKRS2004.Add",
        "QuantumArithmetic.JHHA2016.Add_Mod2N",
    ],
)
@pytest.mark.parametrize("n", [2, 4, 8, 16])
def test_division(div_type: str, adder: str, n: int):
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder=" + adder + "}"
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x // y
        assert r == x % y


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
def test_division_with_QFT_Adder(div_type: str):
    adder = "Std.Arithmetic.FourierTDIncByLE"
    n = 5
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder=" + adder + "}"
    for _ in range(2):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x // y
        assert r == x % y


@pytest.mark.parametrize("div_type", ["Divide_Restoring", "Divide_NonRestoring"])
def test_division_large(div_type: str):
    adder = "Std.Arithmetic.RippleCarryCGIncByLE"
    n = 100
    op = f"QuantumArithmetic.TMVH2019Test.Test_{div_type}"
    cfg = "new QuantumArithmetic.TMVH2019.Config{Adder=" + adder + "}"
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        q, r = eval(f"{op}({n},{x}L,{y}L,{cfg})")
        assert q == x // y
        assert r == x % y


@pytest.mark.parametrize("n", [2, 3, 4, 8, 16, 32, 64, 77, 100])
def test_Divide(n: int):
    op = "QuantumArithmetic.TMVH2019.Divide"
    x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
    x1, y1, z1 = eval(f"TestUtils.TernaryOp({n},{n-1},{n},{x}L,{y}L,0L,{op})")
    assert (x1, y1, z1) == (x % y, y, x // y)


def test_superposition():
    init(project_root="./lib/")
    n = 8
    op = "QuantumArithmetic.TMVH2019.Divide"
    x0 = IntSuperposition.random_of_two(0, 2**n - 1)
    x1 = IntSuperposition.random_of_two(1, 2 ** (n - 1) - 1)
    program = "\n".join(
        [
            x0.write_to_register(n, "q0"),
            x1.write_to_register(n-1, "q1"),
            f"use q2 = Qubit[{n}];",
            f"{op}(q0,q1,q2);",
        ]
    )
    eval(program)
    state = read_superposition(out_size=n)
    expected_state = apply_binary_op(x0, x1, lambda x, y: x // y)
    assert state == expected_state
