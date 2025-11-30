# Common Subexpression Elimination and C Code Generation

This repository provides a small MATLAB utility for performing common subexpression elimination (CSE) on symbolic expressions and emitting equivalent MATLAB and C code.

## Files

- `cse.m`  
  Core function. Takes a symbolic expression (scalar, vector, or matrix) and returns:
  - MATLAB code with factored powers and extracted common subexpressions
  - C code using `double` / `double _Complex`

- `cse_print.m`  
  Convenience wrapper around `cse` that prints MATLAB and C code for quick inspection.

- `test_cse.m`  
  Simple smoke tests covering scalars, vectors, matrices, complex expressions, and cell input.

## Requirements

- MATLAB
- Symbolic Math Toolbox

Tested with recent MATLAB versions, but the code is mostly standard Symbolic Toolbox API.

## Usage

### Basic

```matlab
syms a b c x
expr = a*x^2 + b*x^2 + c;

[m_code, c_code] = cse(expr);

disp(m_code);
disp(c_code);
```

### Using `cse_print`

```matlab
syms a b c x
expr = a*x^2 + b*x^2 + c;

cse_print(expr);
```

Example output:

```matlab
--- MATLAB code ---
x_2 = x*x;
expr = c + x_2*(a + b);
```

```c
--- C code ---
double x_2 = x*x;
double expr = c+x_2*(a+b);
```

### Vectors and matrices

```matlab
syms a b c x
A = [a*x, b; c, b + a*x];

cse_print(A);
```

Example output (MATLAB):

```matlab
tmp1 = a*x;
A = [ ...
  tmp1, b; ...
  c, b + tmp1
];
```

### Function signature

```matlab
[m_code, c_code] = cse(r, tmp_name, ncse, max_power)
```

- `r`           – symbolic expression, vector/matrix, string, or cell of strings
- `tmp_name`    – prefix for temporaries (default: `'tmp'`)
- `ncse`        – max number of CSE iterations (default: `10`)
- `max_power`   – max power to extract as a separate temp (default: `10`)

Output:

- `m_code` – MATLAB code as a single string with newlines
- `c_code` – C code as a single string with newlines

## Code generation details

- A preprocessing step applies `simplify(collect(r))` to expose algebraic structure for CSE.
- Powers of symbols (`x^2`, `a^3`, etc.) are optionally extracted into temps (`x_2`, `a_3`, …) up to `max_power`.
- CSE is done via `subexpr` and only eliminates structurally identical subexpressions.
- C code:
  - Uses `double` by default and promotes to `double _Complex` when needed.
  - Flattens vectors/matrices to 1D arrays using MATLAB’s column-major linear indexing (`A(:)` order).

## Running tests

From MATLAB:

```matlab
test_cse;
```

This prints the original symbolic expression and the generated MATLAB and C code for several test cases.

