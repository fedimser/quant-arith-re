"""Helpers to test superposition."""

import random
import math
import qsharp
from dataclasses import dataclass
from typing import Callable


def _reverse_int(nbits, x):
    return sum(2 ** (nbits - 1 - i) * ((x >> i) % 2) for i in range(nbits))


@dataclass(frozen=True)
class IntSuperposition:
    """Superposition of multiple integers with given probabilities.

    Value with probability p has real amplitude p**0.5
    """

    value_to_prob: dict[int, float]

    def __post_init__(self):
        # Validate that probabilities add up to 1.
        assert math.isclose(sum(self.value_to_prob.values()), 1.0, abs_tol=1e-9)

    @staticmethod
    def random_of_two(a, b):
        """Random superposition of 2 distinct inetegrs in range [a,b]."""
        v1, v2 = 0, 0
        while v1 == v2:
            v1, v2 = random.randint(a, b), random.randint(a, b)
        p1 = random.uniform(0, 1)
        p2 = 1 - p1
        return IntSuperposition({v1: p1, v2: p2})

    def write_to_register(self, n, register_name) -> str:
        """Q# code that creates n-qubit register and writes this superposition there."""
        assert len(self.value_to_prob) == 2
        x1, x2 = self.value_to_prob.keys()
        a1 = self.value_to_prob[x1] ** 0.5
        a2 = self.value_to_prob[x2] ** 0.5
        assert 0 <= x1 < 2**n
        assert 0 <= x2 < 2**n
        return "\n".join(
            [
                f"use {register_name} = Qubit[{n}];",
                f"TestUtils.PrepareSuperposition({register_name}, {a1}, {x1}, {a2}, {x2});",
            ]
        )

    def __eq__(self, other):
        if self.value_to_prob.keys() != other.value_to_prob.keys():
            return False
        return all(
            math.isclose(
                abs(self.value_to_prob[v] - other.value_to_prob[v]), 0, abs_tol=1e-9
            )
            for v in self.value_to_prob
        )


def apply_unary_op(x: IntSuperposition, op: Callable[[int], int]) -> IntSuperposition:
    """Applies classical unary operation to superposition."""
    ans = dict()
    for v1, p1 in x.value_to_prob.items():
        result = op(v1)
        ans[result] = ans.get(result, 0.0) + p1
    return IntSuperposition(ans)


def apply_binary_op(
    x: IntSuperposition, y: IntSuperposition, op: Callable[[int, int], int]
) -> IntSuperposition:
    """Applies classical binary operation to superposition."""
    ans = dict()
    for v1, p1 in x.value_to_prob.items():
        for v2, p2 in y.value_to_prob.items():
            result = op(v1, v2)
            ans[result] = ans.get(result, 0.0) + p1 * p2
    return IntSuperposition(ans)


def read_superposition(out_size) -> IntSuperposition:
    """Reads superposition from current simulation state, projected on last `out_size` qubits.

    The result will contain all possible measurement results for last `out_size`
    qubits (interpreted as little-endian integer resgister), with probabilities
    to get those resutls.
    """
    ans = dict()
    dump = qsharp.dump_machine()
    for state_id in dump:
        val = _reverse_int(out_size, state_id % (2**out_size))
        amplitude = dump[state_id]
        ans[val] = ans.get(val, 0) + abs(amplitude) ** 2
    return IntSuperposition(ans)


def check_superposition_unary_inplace(n: int, op: str, classical_op: Callable[[int], int]):
    """Checks that unary operation acts correctly on superposition.

    Initializes n-qubit register to superposition of two random inetgers,
    applies given operation and checks that result is expected superposition.
    """
    qsharp.init(project_root="./lib/")
    x1 = IntSuperposition.random_of_two(0, 2**n-1)
    program = x1.write_to_register(n, "q") + f"{op}(q);"
    qsharp.eval(program)
    state = read_superposition(out_size=n)
    expected_state = apply_unary_op(x1, classical_op)
    assert state == expected_state, f"{state}=={expected_state}"


def check_superposition_binary_inplace(
    n: int, op: str, classical_op: Callable[[int, int], int]
):
    """Checks that binary in-place operation acts correctly on superposition.

    Initializes two n-qubit registers each to superposition of two random
    inetgers, applies given operation and checks that result in second register
    is the expected superposition.
    """
    qsharp.init(project_root="./lib/")
    x0 = IntSuperposition.random_of_two(0, 2**n-1)
    x1 = IntSuperposition.random_of_two(0, 2**n-1)
    program = "\n".join(
        [x0.write_to_register(n, "q0"), x1.write_to_register(n, "q1"), f"{op}(q0,q1);"],
    )
    qsharp.eval(program)
    state = read_superposition(out_size=n)
    expected_state = apply_binary_op(x0, x1, classical_op)
    assert state == expected_state, f"{state}=={expected_state}"


def check_superposition_binary(
    n: list[int], op: str, classical_op: Callable[[int, int], int]
):
    """Checks that binary operation acts correctly on superposition.

    Initializes three registers of sizes n[0], n[1], n[2]. First two will 
    contain superposition of two random integers, and third one will be 
    initialized to zeros. The applies given operation and checks that result in
    the third second register is the expected superposition.
    """
    qsharp.init(project_root="./lib/")
    x0 = IntSuperposition.random_of_two(0, 2**n[0]-1)
    x1 = IntSuperposition.random_of_two(0, 2**n[1]-1)
    program = "\n".join(
        [
            x0.write_to_register(n[0], "q0"),
            x1.write_to_register(n[1], "q1"),
            f"use q2 = Qubit[{n[2]}];",
            f"{op}(q0,q1,q2);",
        ]
    )
    qsharp.eval(program)
    state = read_superposition(out_size=n[2])
    expected_state = apply_binary_op(x0, x1, classical_op)
    assert state == expected_state, f"{state}=={expected_state}"
