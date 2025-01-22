# Quantum Arithmetic Algorithms and Resource Estimation

This repository contains a library of Quantum Arithmetic algorithms and 
experiments on their resource estimation. It was created as a project in
[Quantum Open Source Foundation](https://qosf.org) Mentorship Program (cohort 10).

## Repository structure
  * `src` - implementation of various algorithms in Q#. Each file corresponds to a research paper, which implementing one or more algorithms. Typicaly, a file name consists of author's initials and year when the paper was published. Each such file has a reference to the paper it implements.
  * `test` - tests using Q# simulator (written in Python, using `qsharp` Python library).
  * `resource_estimate` - experiments on resource estimation of some algorithms, using the [Azure Quantum Resource Estimator](https://learn.microsoft.com/en-us/azure/quantum/intro-to-resource-estimation).
  * `resource_estimate/results` - raw results of experiments, in CSV format.

This repository is designed to be used as a [Q# library](https://github.com/microsoft/qsharp/wiki/Q%23-External-Dependencies-(Libraries)).

## Algorithms

We implemented many different algorithms and compared them. Below we list the algorithms we recommend to use (if you just need an algorithm for the given task). All of the recommended algorithms use Clifford+T gate set and can be efficiently simulated.

* Addition - use algorithms from the [standard library](https://github.com/microsoft/qsharp/blob/main/library/std/src/Std/Arithmetic.qs), e.g. `Std.Arithmetic.RippleCarryCGIncByLE`.
* Subtraction - `QuantumArithmetic.Utils.Subtract`.
* Multiplication - `QuantumArithmetic.MCT2017.Multiply`.
* Division - `QuantumArithmetic.TMVH2019.Divide`.
* Modular exponentiation - `QuantumArithmetic.LYY2021.ModExpWindowedOptimal`.

## Advanced algorithms

The library also has these advanced algorithms:

* Table lookup - `QuantumArithmetic.TableFunctions.TableLookup`.
* Square root - `QuantumArithmetic.MCT2018.SquareRoot`.
* Greatest common divisor - `QuantumArithmetic.MSIM2013.GreatestCommonDivisor`.
