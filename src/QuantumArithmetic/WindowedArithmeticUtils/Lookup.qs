open Microsoft.Quantum.Intrinsic;
open Microsoft.Quantum.Canon;
open Microsoft.Quantum.Convert;
open QuantumArithmetic.WindowedArithmeticUtils.Fixes;
open QuantumArithmetic.WindowedArithmeticUtils.And;
open QuantumArithmetic.WindowedArithmeticUtils.Xor;
open QuantumArithmetic.WindowedArithmeticUtils.Util;
open QuantumArithmetic.WindowedArithmeticUtils.Addition;

/// # Summary
/// Performs 'a ^^^= T[b]' where 'a' and 'b' are little-endian quantum registers
/// and 'T' is a classical table.
///
/// Bits in 'T[b]' beyond the range of 'a' are ignored.
/// It is assumed that the address will never store a value beyond the end of the table.
/// Invalid addresses cause undefined behavior.
///
/// # Input
/// ## lvalue
/// The target of the xor. The 'a' in 'a ^^^= T[b]'.
/// ## table
/// The classical table containing integers to choose between and xor into the target.
/// The 'T' in 'a ^^^= T[b]'.
/// ## address
/// Determines which integer from the table will be xored into the target.
/// The 'b' in 'a ^^^= T[b]'.
operation XorEqualLookup (lvalue: LittleEndian, table: BigInt[], address: LittleEndian) : Unit {
    body (...) {
        Controlled XorEqualLookup([], (lvalue, table, address));
    }
    adjoint self;
    controlled (cs, ...) {
        if (Length(table) == 0) {
            fail "Can't lookup values in an empty table.";
        }

        // Drop high bits that would place us beyond the range of the table.
        let maxAddressLen = CeilLg2(Length(table));
        if (maxAddressLen < Length(address!)) {
            let kept = LittleEndian(address![0..maxAddressLen - 1]);
            return Controlled XorEqualLookup(cs, (lvalue, table, kept));
        }

        // Drop inaccessible parts of table.
        let maxTableLen = 1 <<< Length(address!);
        if (maxTableLen < Length(table)) {
            let kept = table[0..maxTableLen-1];
            return Controlled XorEqualLookup(cs, (lvalue, kept, address));
        }

        // Base case: singleton table.
        if (Length(table) == 1) {
            XorEqualConst(address, IntAsBigInt(-1));
            Controlled XorEqualConst(cs + address!, (lvalue, table[0]));
            XorEqualConst(address, IntAsBigInt(-1));
            return ();
        }

        // Recursive case: divide and conquer.
        let highBit = address![Length(address!) - 1];
        let restAddress = LittleEndian(address![0..Length(address!) - 2]);
        let h = 1 <<< (Length(address!) - 1);
        let lowTable = table[0..h-1];
        let highTable = table[h..Length(table)-1];
        use q = Qubit() {
            // Store 'all(controls) and not highBit' in q.
            X(highBit);
            Controlled InitToggle(cs + [highBit], q);
            X(highBit);

            // Do lookup for half of table where highBit is 0.
            Controlled XorEqualLookup([q], (lvalue, lowTable, restAddress));

            // Flip q to storing 'all(controls) and highBit'.
            Controlled X(cs, q);

            // Do lookup for half of table where highBit is 1.
            Controlled XorEqualLookup([q], (lvalue, highTable, restAddress));

            // Eager uncompute 'q = all(controls) and highBit'.
            Controlled UncomputeToggle(cs + [highBit], q);
        }
    }
    controlled adjoint self;
}

/// # Summary
/// Performs 'a := T[b]' where 'a' and 'b' are little-endian quantum registers and 'T' is a classical table.
///
/// Bits in 'T[b]' beyond the range of 'a' are ignored.
/// It is assumed that the address will never store a value beyond the end of the table.
/// Invalid addresses cause undefined behavior.
///
/// # Input
/// ## lvalue
/// The target of the initialization. The 'a' in 'a := T[b]'.
/// ## table
/// The classical table containing integers to choose between to initialize the target.
/// The 'T' in 'a := T[b]'.
/// ## address
/// Determines which integer from the table will be the target's value.
/// The 'b' in 'a := T[b]'.
///
/// # Reference
/// - "Encoding Electronic Spectra in Quantum Circuits with Linear T Complexity"
///        Ryan Babbush, Craig Gidney, Dominic W. Berry, Nathan Wiebe, Jarrod McClean, Alexandru Paler, Austin Fowler, Hartmut Neven
///        https://arxiv.org/abs/1805.03662
operation LetLookup (lvalue: LittleEndian, table: BigInt[], address: LittleEndian) : Unit {
    body (...) {
        XorEqualLookup(lvalue, table, address);
    }
    adjoint (...) {
        Controlled Adjoint LetLookup([], (lvalue, table, address));
    }
    controlled auto;
    controlled adjoint (cs, ...) {
        Controlled XorEqualLookup(cs, (lvalue, table, address));

        // HACK: disabled to make testing with Toffoli simulator viable.
        // let n = Min(Length(address!), CeilLg2(Length(table)));
        // let max = Min(1 <<< n, Length(table));
        // let n_low = Min((n >>> 1), FloorLg2(Length(lvalue!)));
        // let n_high = n - n_low;
        // let low = LittleEndian(address![0..n_low-1]);
        // let high = LittleEndian(address![n_low..n-1]);
        // mutable fixups = new BigInt[1 <<< n_high];

        // // Determine fixups by performing eager measurements.
        // for (i in 0..Length(lvalue!)-1) {
        //     if (MResetX(lvalue![i]) == One) {
        //         for (j in 0..max-1) {
        //             if ((table[j] &&& (IntAsBigInt(1) <<< i)) != IntAsBigInt(0)) {
        //                 let fixup_index = j >>> n_low;
        //                 let fixup_bit = j &&& ((1 <<< n_low) - 1);
        //                 set fixups[fixup_index] = fixups[fixup_index] ^^^ (IntAsBigInt(1) <<< fixup_bit);
        //             }
        //         }
        //     }
        // }

        // // Perform fixups.
        // let low_unary = LittleEndian(lvalue![0..(1<<<n_low)-1]);
        // LetUnary(low_unary, low);
        // for (t in low_unary!) {
        //     H(t);
        // }
        // Controlled XorEqualLookup(cs, (low_unary, fixups, high));
        // for (t in low_unary!) {
        //     H(t);
        // }
        // DelUnary(low_unary, low);
    }
}

/// # Summary
/// Uncomputes a register initialized using 'a := T[b]', where 'a' and 'b' are
/// little-endian quantum registers and 'T' is a classical table.
///
/// Bits in 'T[b]' beyond the range of 'a' are ignored.
/// It is assumed that the address will never store a value beyond the end of the table.
/// Invalid addresses cause undefined behavior.
///
/// # Input
/// ## lvalue
/// The target to uncompute. The 'a' from 'a := T[b]'.
/// ## table
/// The classical table containing integers that the target may be set to.
/// The 'T' from 'a := T[b]'.
/// ## address
/// Determines which integer from the table is supposed to be the target's value.
/// The 'b' from 'a := T[b]'.
operation DelLookup (lvalue: LittleEndian, table: BigInt[], address: LittleEndian) : Unit {
    body (...) {
        Adjoint LetLookup(lvalue, table, address);
    }
    adjoint auto;
    controlled auto;
    controlled adjoint auto;
}

/// # Summary
/// Performs 'a += T[b]' where 'a' and 'b' are little-endian quantum registers
/// and 'T' is a classical table.
///
/// Bits in 'T[b]' beyond the range of 'a' are ignored.
/// It is assumed that the address will never store a value beyond the end of the table.
/// Invalid addresses cause undefined behavior.
///
/// # Input
/// ## lvalue
/// The target of the addition. The 'a' in 'a += T[b]'.
/// ## table
/// The classical table containing integers to choose between and add into the target.
/// The 'T' in 'a += T[b]'.
/// ## address
/// Determines which integer from the table will be added into the target.
/// The 'b' in 'a += T[b]'.
operation PlusEqualLookup (lvalue: LittleEndian, table: BigInt[], address: LittleEndian) : Unit {
    body (...) {
        Controlled PlusEqualLookup([], (lvalue, table, address));
    }
    adjoint auto;
    controlled (cs, ...) {
        use t_reg = Qubit[Length(lvalue!)] {
            let t = LittleEndian(t_reg);
            Controlled LetLookup(cs, (t, table, address));
            PlusEqual(lvalue, t);
            Controlled DelLookup(cs, (t, table, address));
        }
    }
    controlled adjoint auto;
}

