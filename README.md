# `cse` – Common Subexpression Elimination

```matlab
function [m_code, c_code] = cse(r, tmp_name, ncse)
% Common subexpression elimination (CSE) - extracts repeated expressions as temporary variables
% Input: 
%        r = symbolic expression(s)
%        tmp_name = prefix for temp vars, optional, default: 'tmp'
%        ncse = max iterations, optional, default: 10
% Output: 
%        m_code = MATLAB code string with all assignments
%        c_code = C code string equivalent
```

Common subexpression elimination (CSE) for symbolic expressions.  
Automatically extracts repeated subexpressions and powers of variables as temporary variables. 
Handles complex numbers and type inference. 
Generates executable, type-correct code in both MATLAB and C (C99) formats.

## Syntax

```matlab
[m_code, c_code] = cse(r, tmp_name, ncse)
```

## Inputs

- `r`  
  Symbolic expression or array of symbolic expressions to be simplified.

- `tmp_name`  
  String prefix used for naming temporary variables (e.g. `"tmp"` → `tmp1`, `tmp2`, …).  
  Default: `'tmp'`

- `ncse`  
  Maximum number of CSE iterations to perform.  
  Default: `10`

## Outputs

- `m_code`  
  String containing executable MATLAB code with all temporary variable assignments  
  and final result assignment in proper format.

- `c_code`  
  String containing equivalent C99 code with type declarations and array syntax.

## Features

- **Common subexpression elimination**: Detects and extracts repeated subexpressions
- **Power extraction**: Automatically factors out repeated powers (e.g., `a^2`, `a^3`) with efficient chaining (`a_3 = a_2 * a`)
- **Complex number handling**: Detects imaginary content and declares variables as `double _Complex` when needed
- **Type inference**: Propagates complex types—if any temporary is complex, result arrays are also complex
- **Proper C syntax**: Converts MATLAB operators and functions to C equivalents (e.g., `^` → `pow()`, `1i` → `1*I`)
- **Array indexing**: Generates 0-based indexed array assignments for C

## Example

Run a demo with no arguments to generate MATLAB and C code for the solution of a cubic equation:

```matlab
>> [m_code, c_code] = cse;
--- Expression: (scroll to the right to see all
r =
                                                                                                                                                                                                                                                                                                                         (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3) - b/(3*a) - (- b^2/(9*a^2) + c/(3*a))/(((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3)
(- b^2/(9*a^2) + c/(3*a))/(2*(((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3)) - (3^(1/2)*((- b^2/(9*a^2) + c/(3*a))/(((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3) + (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3))*1i)/2 - b/(3*a) - (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3)/2
(- b^2/(9*a^2) + c/(3*a))/(2*(((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3)) + (3^(1/2)*((- b^2/(9*a^2) + c/(3*a))/(((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3) + (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3))*1i)/2 - b/(3*a) - (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (- b^2/(9*a^2) + c/(3*a))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3)/2
--- With CSE (MATLAB):
a_2 = a^2;
a_3 = a*a_2;
b_2 = b^2;
b_3 = b*b_2;
tmp1 = (((b_3/(27*a_3) + d/(2*a) - (b*c)/(6*a_2))^2 - (b_2/(9*a_2) - c/(3*a))^3)^(1/2) - d/(2*a) - b_3/(27*a_3) + (b*c)/(6*a_2))^(1/3);
tmp2 = -(b_2/(9*a_2) - c/(3*a))/tmp1;
tmp3 = -b/(3*a);
tmp4 = (3^(1/2)*(tmp1 + tmp2)*1i)/2;
r = [ ... 
tmp1 + tmp3 + (b_2/(9*a_2) - c/(3*a))/tmp1; ...
             tmp2/2 - tmp1/2 + tmp3 - tmp4; ...
             tmp2/2 - tmp1/2 + tmp3 + tmp4];
--- With CSE (C):
double a_2 = a*a;
double a_3 = a*a_2;
double b_2 = b*b;
double b_3 = b*b_2;
double tmp1 = pow((b_3*(-1.0/2.7E+1))/a_3-d/(a*2.0)+sqrt(pow(b_3/(a_3*2.7E+1)+d/(a*2.0)-(b*c)/(a_2*6.0),2.0)-pow(b_2/(a_2*9.0)-c/(a*3.0),3.0))+(b*c)/(a_2*6.0),1.0/3.0);
double tmp2 = -(b_2/(a_2*9.0)-c/(a*3.0))/tmp1;
double tmp3 = (b*(-1.0/3.0))/a;
double _Complex tmp4 = sqrt(3.0)*(tmp1+tmp2)*5.0E-1*sqrt(-1.0);
double _Complex r[3];
r[0] = tmp1+tmp3+(b_2/(a_2*9.0)-c/(a*3.0))/tmp1;
r[1] = tmp1*(-1.0/2.0)+tmp2/2.0+tmp3-tmp4;
r[2] = tmp1*(-1.0/2.0)+tmp2/2.0+tmp3+tmp4;
>> 
```

Both `m_code` and `c_code` are returned as strings containing complete, executable code ready to be used or further integrated into larger applications.
