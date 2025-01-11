operation BinaryOpExtraOut(n : Int, x_val : Int, y_val : Int, op : (Qubit[], Qubit[], Qubit[], Qubit) => Unit) : Int {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit[n];
    use z_extra = Qubit();
    ApplyPauliFromInt(PauliX, true, x_val, x);
    ApplyPauliFromInt(PauliX, true, y_val, y);
    op(x, y, z, z_extra);
    let new_x = MeasureInteger(x);
    // Fact(new_x == x_val, "x was changed.");
    let new_z = MeasureInteger(z);
    // Fact(new_z == y_val, "z was not changed to y.");
    let results = y + [z_extra];
    let ans = MeasureInteger(results);
    return ans;
}

operation RunBinaryOpInPlace(n : Int, op : (Qubit[], Qubit[]) => Unit) : Unit {
    use a = Qubit[n];
    use b = Qubit[n];
    op(a, b);
}

operation Run3WayOp(n1 : Int, n2 : Int, n3 : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : Unit {
    use a = Qubit[n1];
    use b = Qubit[n2];
    use c = Qubit[n3];
    op(a, b, c);
}

operation RunMultiply(n : Int, op : (Qubit[], Qubit[], Qubit[]) => Unit) : Unit {
    use a = Qubit[n];
    use b = Qubit[n];
    use ans = Qubit[2 * n];
    op(a, b, ans);
}

operation RunConstantAdder(n : Int, op : (BigInt, Qubit[]) => Unit) : Unit {
    // For consistency, use a number of form 101010..0101.
    mutable A : BigInt = 0L;
    for i in 0..2..n-1 {
        set A += (1L <<< i);
    }
    use B = Qubit[n];
    op(A, B);
}

operation RunModExp(n : Int, op : (Qubit[], Qubit[], BigInt, BigInt) => Unit) : Unit {
    use ans = Qubit[n];
    use x_qubits = Qubit[n];
    let N = (1L <<< n)-1L;
    mutable a : BigInt = 59604644783353249L;  // A fixed prime number.
    op(x_qubits, ans, a, N);
}

operation RunRadix(n: Int, radix: Int, op : (Qubit[], Qubit[], Qubit[], Int, (Qubit[], Qubit[], Qubit[]) => Unit is Adj) => Unit is Adj, adder_op: (Qubit[], Qubit[], Qubit[]) => Unit is Adj) : Unit {
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n];
    op(a, b, c, radix, adder_op);
}

operation RunRadixCarry(n: Int, radix: Int, op : (Qubit[], Qubit[], Qubit[], Int, (Qubit[], Qubit[], Qubit[], Qubit) => Unit is Adj) => Unit is Adj, adder_op: (Qubit[], Qubit[], Qubit[], Qubit) => Unit is Adj) : Unit {
    use a = Qubit[n];
    use b = Qubit[n];
    use c = Qubit[n];
    op(a, b, c, radix, adder_op);
}