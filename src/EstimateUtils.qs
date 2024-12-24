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