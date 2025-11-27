# `cse.m` – Common Subexpression Elimination

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
Repeated subexpressions are extracted and replaced by temporary variables.  
Generates executable code in both MATLAB and C formats.

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
  String containing equivalent C code with type declarations and array syntax.

## Example

Run with no arguments to generate MATLAB and C code for the cubic equation solution:

```matlab
>> [m_code, c_code] = cse
--- Expression:
--- With CSE (MATLAB):
tmp1 = (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (c/(3*a) - b^2/(9*a^2))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3);
tmp2 = (c/(3*a) - b^2/(9*a^2))/tmp1;
tmp3 = -b/(3*a);
tmp4 = (3^(1/2)*(tmp1 + tmp2)*1i)/2;
r = [ ... 
           tmp1 - tmp2 + tmp3; ...
tmp2/2 - tmp1/2 + tmp3 - tmp4; ...
tmp2/2 - tmp1/2 + tmp3 + tmp4];
--- With CSE (C):
double tmp1 = (((d/(2*a) + pow(b,3/(27*pow(a,3) - (b*c)/(6*pow(a,2))pow2 + (c/(3*a) - pow(b,2/(9*pow(a,2))pow3)pow(1/2) - pow(b,3/(27*pow(a,3) - d/(2*a) + (b*c)/(6*pow(a,2))pow(1/3);
double tmp2 = (c/(3*a) - pow(b,2/(9*pow(a,2))/tmp1;
double tmp3 = -b/(3*a);
double tmp4 = (pow(3,(1/2)*(tmp1 + tmp2)*1I)/2;
double r[3] = {[tmp1 - tmp2 + tmp3; tmp2/2 - tmp1/2 + tmp3 - tmp4; tmp2/2 - tmp1/2 + tmp3 + tmp4]};

m_code = 
    "tmp1 = (((d/(2*a) + b^3/(27*a^3) - (b*c)/(6*a^2))^2 + (c/(3*a) - b^2/(9*a^2))^3)^(1/2) - b^3/(27*a^3) - d/(2*a) + (b*c)/(6*a^2))^(1/3);
     tmp2 = (c/(3*a) - b^2/(9*a^2))/tmp1;
     tmp3 = -b/(3*a);
     tmp4 = (3^(1/2)*(tmp1 + tmp2)*1i)/2;
     r = [ ... 
                tmp1 - tmp2 + tmp3; ...
     tmp2/2 - tmp1/2 + tmp3 - tmp4; ...
     tmp2/2 - tmp1/2 + tmp3 + tmp4];"

c_code = 
    "double tmp1 = (((d/(2*a) + pow(b,3/(27*pow(a,3) - (b*c)/(6*pow(a,2))pow2 + (c/(3*a) - pow(b,2/(9*pow(a,2))pow3)pow(1/2) - pow(b,3/(27*pow(a,3) - d/(2*a) + (b*c)/(6*pow(a,2))pow(1/3);
     double tmp2 = (c/(3*a) - pow(b,2/(9*pow(a,2))/tmp1;
     double tmp3 = -b/(3*a);
     double tmp4 = (pow(3,(1/2)*(tmp1 + tmp2)*1I)/2;
     double r[3] = {[tmp1 - tmp2 + tmp3; tmp2/2 - tmp1/2 + tmp3 - tmp4; tmp2/2 - tmp1/2 + tmp3 + tmp4]};"
```

Both `m_code` and `c_code` are returned as strings containing the complete, executable code.
