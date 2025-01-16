import Std.Diagnostics.Fact;
import TestUtils.*;

operation BinaryOpInPlaceCarryIn(n : Int, x_val : BigInt, y_val : BigInt, carry : BigInt, op : (Qubit[], Qubit[], Qubit) => Unit) : BigInt {
    use x = Qubit[n];
    use y = Qubit[n];
    use z = Qubit();
    ApplyBigInt(x_val, x);
    ApplyBigInt(y_val, y);
    if(carry == 1L){
        X(z);
    }
    op(x, y, z);
    let new_x = MeasureBigInt(x);
    Fact(new_x == x_val, "x was changed.");
    let new_z = MeasureBigInt([z]);
    Fact(new_z == carry, "z was changed.");
    let ans = MeasureBigInt(y);
    return ans;
}