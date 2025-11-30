
% TEST_CSE Basic smoke tests for cse() and cse_print().
%
% Requires Symbolic Math Toolbox.

clear; clc;

fprintf('Running test_cse.m...\n\n');

% 1) Simple scalar real expression with common subexpression
syms a b c x
expr1 = a*x^2 + b*x^2 + c;
disp('Test 1: scalar real expression with x^2 common');
cse_print(expr1);

% 2) Higher powers of a single symbol
expr2 = a^2 + a^3 + a^4;
disp('Test 2: powers of a');
cse_print(expr2, 'tmp', 10, 6);  % allow powers up to 6

% 3) Vector expression
r_vec = [a*x; b*x; a*x + b*x];
disp('Test 3: vector expression');
cse_print(r_vec);

% 4) Matrix expression
A = [a*x, b; c, a*x + b];
disp('Test 4: matrix expression');
cse_print(A);

% 5) Complex-valued expression
syms z
expr_complex = (a + 2i)*x + z;
disp('Test 5: complex expression');
cse_print(expr_complex);

% 6) Cell input
expr_cell = {'a*x^2 + b', 'c*x^2 + d'};
disp('Test 6: cell input');
cse_print(expr_cell);

fprintf('\nAll basic tests executed. Inspect output manually for now.\n');
