# `cse.m` – Common Subexpression Elimination for Symbolic Expressions

```matlab
function [r, defs] = cse(r, tmp_name, ncse)
% Common subexpression elimination (CSE) - extracts repeated expressions as temporary variables
% Input: 
%        r = symbolic expression(s)
%        tmp_name = prefix for temp vars, ncse = max iterations
% Output: 
%        r = simplified expression
%        defs = struct of substituted subexpressions
```

Common subexpression elimination (CSE) for symbolic expressions.  
Repeated subexpressions are extracted and replaced by temporary variables.

## Syntax

```matlab
[r, defs] = cse(r, tmp_name, ncse)
```

## Inputs

- `r`  
  Symbolic expression or array of symbolic expressions to be simplified.

- `tmp_name`  
  String prefix used for naming temporary variables (e.g. `"t"` → `t1`, `t2`, …).

- `ncse`  
  Maximum number of CSE iterations to perform.

## Outputs

- `r`  
  Simplified symbolic expression(s) with common subexpressions replaced by temporaries.

- `defs`  
  Struct containing the definitions of substituted subexpressions,  
  mapping each temporary variable name to its corresponding expression.
