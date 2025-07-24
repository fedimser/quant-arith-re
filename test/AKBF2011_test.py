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


@pytest.mark.parametrize("n", [2, 4, 8, 16, 24, 32, 63])
def test_division(n: int):
    op = "QuantumArithmetic.AKBF2011.Divide_Restoring"
    for _ in range(5):
        x, y = random.randint(0, 2**n - 1), random.randint(1, 2 ** (n - 1) - 1)
        q, r = eval(f"TestUtils.Test_Divide_Restoring({n},{x},{y},{op})")
        assert r == x % y
        assert q == x // y


def test_superposition():
    init(project_root="./lib/")
    n = 8
    op = "QuantumArithmetic.AKBF2011.Divide_Restoring"
    x0 = IntSuperposition.random_of_two(0, 2**n - 1)
    x1 = IntSuperposition.random_of_two(1, 2 ** (n - 1) - 1)
    program = "\n".join(
        [
            x0.write_to_register(n, "q0"),
            x1.write_to_register(n, "q1"),
            f"use q2 = Qubit[{n}];",
            f"{op}(q0,q1,q2);",
        ]
    )
    eval(program)
    state = read_superposition(out_size=n)
    expected_state = apply_binary_op(x0, x1, lambda x, y: x // y)
    assert state == expected_state
