
function cse_print(r, tmp_name, ncse, max_power)
% CSE_PRINT Convenience helper to run cse() and print MATLAB & C code.
%
%   cse_print(r)
%   cse_print(r, tmp_name)
%   cse_print(r, tmp_name, ncse)
%   cse_print(r, tmp_name, ncse, max_power)

if nargin < 2, tmp_name  = 'tmp'; end
if nargin < 3, ncse      = 10;   end
if nargin < 4, max_power = 10;   end

[m_code, c_code] = cse(r, tmp_name, ncse, max_power);

disp(' ');
disp('--- Matlab code ---');
disp(r);
disp('--- MATLAB code with CSE ---');
disp(m_code);
disp(' ');
disp('--- C code with CSE ---');
disp(c_code);
end
