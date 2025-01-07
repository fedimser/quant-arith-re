    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open QuantumArithmetic.WindowedArithmeticUtils.Fixes;
    open QuantumArithmetic.WindowedArithmeticUtils.Util;
    open QuantumArithmetic.WindowedArithmeticUtils.Lookup;

    function MultiplicationTable(factor: BigInt, length: Int) : BigInt[] {
        mutable table = [0L, size=length];
        for i in 0..Length(table)-1 {
            set table w/= i <- IntAsBigInt(i)*factor;
        }
        return table;
    }

    operation PlusEqualConstTimesLEWindowed (lvalue: LittleEndian,
                                             classical_factor: BigInt,
                                             quantum_factor: LittleEndian,
                                             window: Int) : Unit {
        body (...) {
            let table = MultiplicationTable(classical_factor, 1 <<< window);
            for i in 0..window..Length(quantum_factor!)-1 {
                let w = SliceLE(quantum_factor, i, i+window);
                let t = SkipLE(lvalue, i);
                PlusEqualLookup(t, table, w);
            }
        }
        adjoint auto;
    }

