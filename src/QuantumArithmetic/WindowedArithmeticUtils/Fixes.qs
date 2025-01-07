// Things I need to upgrade to Modern QDK
newtype LittleEndian = Qubit[];

function BigIntAsBoolArrayClassic(a : BigInt) : Bool[] {
    // To use two's complement, little endian representation of the integer, we fisrt need to track if the input
    // is a negative number. If so, flip it back to positive and start tracking a carry bit.
    let isNegative = a < 0L;
    mutable carry = isNegative;
    mutable val = isNegative ? -a | a;

    mutable arr = [];
    while val != 0L {
        let newBit = val % 2L == 1L;
        if isNegative {
            // For negative numbers we must invert the calculated bit, so treat "true" as "0"
            // and "false" as "1". This means when the carry bit is set, we want to record the
            // calculated new bit and set the carry to the opposite, otherwise record the opposite
            // of the calculate bit.
            if carry {
                set arr += [newBit];
                set carry = not newBit;
            }
            else {
                set arr += [not newBit];
            }
        }
        else {
            // For positive numbers just accumulate the calculated bits into the array.
            set arr += [newBit];
        }

        set val /= 2L;
    }

    // Pad to the next higher byte length (size 8) if the length is not a non-zero multiple of 8 or
    // if the last bit does not agree with the sign bit.
    let len = Length(arr);
    if len == 0 or len % 8 != 0 or arr[len - 1] != isNegative {
        set arr += [isNegative, size = 8 - (len % 8)];
    }
    return arr;
}


