function [r, defs] = cse(r, tmp_name, ncse)
% Common subexpression elimination (CSE) - extracts repeated expressions as temporary variables
% Input: 
%        r = symbolic expression(s)
%        tmp_name = prefix for temp vars, ncse = max iterations
% Output: 
%        r = simplified expression
%        defs = struct of substituted subexpressions

% Set default parameter values
if nargin < 2, tmp_name = 'tmp'; end
if nargin < 3, ncse = 10; end

% Demo mode: solve cubic equation and extract common subexpressions
if nargin == 0
  format compact
  expr = str2sym('a*x^3 + b*x^2 + c*x + d == 0');
  disp('--- Expression:')
  r = solve(expr, sym('x'), 'MaxDegree', 3)
  disp('--- With CSE:')
  [r, defs] = cse(r, 'tmp', 4);
  return
end

% Convert input to symbolic if needed
if ischar(r) || isstring(r)
  r = str2sym(r);
end

% Handle cell array input by converting to symbolic matrix
if iscell(r)
  r = cellfun(@str2sym, r, 'UniformOutput', false);
  r = vertcat(r{:});
end

% Initialize definitions structure
defs = struct();

% Iteratively extract common subexpressions
for i = 1:ncse
  sstr = sprintf('%s%d', tmp_name, i);
  [r_new, sigma] = subexpr(r, sstr);
  if isempty(sigma), break; end  % No more subexpressions found
  fprintf('%s = %s;\n', sstr, char(sigma));  % Print substitution
  defs.(sstr) = sigma;  % Store definition
  r = r_new;  % Update expression with substitution
end

% Get caller's variable name or use default
vname = inputname(1); 
if isempty(vname), vname = 'r'; end

% Display simplified expression in MATLAB format
inputForm(r, vname);

end


function inputForm(A, vname)
% Display A in MATLAB-executable format: vname = A;
% Input: A = symbolic matrix/value, vname = variable name
if nargin == 0
  A = randn(8);
  vname = 'A';
end

nl = newline;
s = evalc('disp(A)');  % Capture display output
[nr, nc] = size(A);

if max(nr, nc) > 1
  % Format multi-element array with line continuations
  s = strrep(s, '[', '');  % Remove opening bracket
  s = strrep(s, ']', '');  % Remove closing bracket
  s = strrep(s, nl, ['; ...', nl]);  % Add line continuations
  s = regexprep(s, '; \.\.\.\s*$', '');  % Remove trailing continuation
  s = [vname, ' = [ ... ', nl, s, '];'];  % Wrap with assignment
else
  % Format single value
  s = [vname, ' = ', strtrim(s), ';'];
end

disp(s)
end