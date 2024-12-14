// this is the main file to handle higher radix used in
// the file WBC2023.qs

// This is the main function that takes the existing numbers in binary (size N) and returns an
// initial state where the addition is able to use the radix for optimization
operation HigherRadix(A: Qubit[], B: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let num_groups : Int = (Length(B)+radix-1)/radix;
    // The first step is to generate the least significant g which is uncomputed last
    within{
        generate_lsg(A, B, ancilla, radix);
    } apply {
        // generate the other g's which are not uncomputed
        generate_other_g(A, B, ancilla, radix);
        use group_ancilla = Qubit[num_groups];
        within{
            generate_p(A, B);

            // RADIX LAYER
            // p = B
            // g = Ancilla


            // new set of ancilla qubits
            // original code created Length(p) qubits for the ancilla
            // however in the example from the paper with 15 qubit integers
            // and 3 radix, only one ancilla per group was needed
            // this might be specific to the example and therefore may need to be changed
            // also note that the Length of the ancilla is used in all of the following functions
            // so those will also need to be changed
            generate_p_groups(B, ancilla, group_ancilla, radix);
            generate_g_groups_pt1(B, ancilla, group_ancilla, radix);
        } apply {
            generate_g_groups_pt2(B, ancilla, group_ancilla, radix);
            //BrentKungTree stuff
        }
    }

}

// generate g for the least significant qubit in each group
// must be uncomputed
operation generate_lsg(A: Qubit[], B: Qubit[], Ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    for i in 0..n-1 {
        if i%radix==0 {
            CCNOT(A[i], B[i], Ancilla[i]);
        } 
    }
}

// generate g for non-least significant qubit in each group 
// does not get uncomputed
operation generate_other_g(A: Qubit[], B: Qubit[], Ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    for i in 0..n-1 {
        if i%radix!=0 {
            CCNOT(A[i], B[i], Ancilla[i]);
        } 
    }
}

// genereates p must be uncomputed
operation generate_p(A: Qubit[], B: Qubit[]) : Unit is Adj + Ctl {
    let n : Int = Length(A);
    for i in 0..n-1 {
        CNOT(A[i], B[i]);
    }
}

// generate p groups which gets uncomputed
operation generate_p_groups(p: Qubit[], g: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(ancilla);
    for i in 0..n-1{
        Controlled X(p[i*radix..(i+1)*radix-1], ancilla[i]);
    }
}

// first part of generating g groups that gets uncomputed.
operation generate_g_groups_pt1(p: Qubit[], g: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(ancilla);
    for i in 0..n-1{
        for j in 0..radix-3{
            CCNOT(g[i*radix+j], p[i*radix+j+1], g[i*radix+j+1]);
        }
    }
}

// second part of gerneate g groups that does NOT get uncomputed as it stores
operation generate_g_groups_pt2(p: Qubit[], g: Qubit[], ancilla : Qubit[], radix : Int) : Unit is Adj + Ctl {
    let n : Int = Length(ancilla);
    let j : Int = radix - 2;
    for i in 0..n-1{
        CCNOT(g[i*radix+j], p[i*radix+j+1], g[i*radix+j+1]);
    }
}