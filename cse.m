function [m_code, c_code] = cse(r, tmp_name, ncse)
% Common subexpression elimination (CSE) - extracts repeated expressions as temporary variables
% Input: 
%        r = symbolic expression(s)
%        tmp_name = prefix for temp vars, optional, default: 'tmp'
%        ncse = max iterations, optional, default: 10
% Output: 
%        m_code = MATLAB code string with all assignments
%        c_code = C code string equivalent

% Set default parameter values
if nargin < 2, tmp_name = 'tmp'; end
if nargin < 3, ncse = 10; end

% Demo mode: solve a cubic equation and extract common subexpressions
if nargin == 0
  format compact
  expr = str2sym('a*x^3 + b*x^2 + c*x + d == 0');
  disp('--- Expression: (scroll to the right to see all')
  r = solve(expr, sym('x'), 'MaxDegree', 3)
  disp('--- With CSE (MATLAB):')
  [m_code, c_code] = cse(r, 'tmp', 4);
  disp(m_code)
  disp('--- With CSE (C):')
  disp(c_code)
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

% Initialize definitions structure and code strings
defs = struct();
m_lines = string([]);
c_lines = string([]);

% Iteratively extract common subexpressions
for i = 1:ncse
  sstr = sprintf('%s%d', tmp_name, i);
  [r_new, sigma] = subexpr(r, sstr);
  if isempty(sigma), break; end  % No more subexpressions found
  
  % Format MATLAB and C assignments
  sigma_str = char(sigma);
  m_lines(end+1) = sprintf('%s = %s;', sstr, sigma_str);
  c_lines(end+1) = sprintf("double %s = %s;", sstr, sym2c(sigma_str));
  
  defs.(sstr) = sigma;  % Store definition
  r = r_new;  % Update expression with substitution
end

% Get caller's variable name or use default
vname = inputname(1); 
if isempty(vname), vname = 'r'; end

% Format final result assignment
[m_assign, c_assign] = formatAssignment(r, vname);
m_lines(end+1) = m_assign;
c_lines(end+1) = c_assign;

% Combine all lines into output code strings
m_code = strjoin(m_lines, newline);
c_code = strjoin(c_lines, newline);

end


function [m_assign, c_assign] = formatAssignment(A, vname)
% Format assignment statement for MATLAB and C
% Input: A = symbolic matrix/value, vname = variable name
% Output: m_assign = MATLAB assignment, c_assign = C assignment

nl = newline;
s = evalc('disp(A)');  % Capture display output
[nr, nc] = size(A);

if max(nr, nc) > 1
  % Format multi-element array with line continuations
  s = strrep(s, '[', '');  % Remove opening bracket
  s = strrep(s, ']', '');  % Remove closing bracket
  s = strrep(s, nl, ['; ...', nl]);  % Add line continuations
  s = regexprep(s, '; \.\.\.\s*$', '');  % Remove trailing continuation
  m_assign = [vname, ' = [ ... ', nl, s, '];'];  % Wrap with assignment
else
  % Format single value
  m_assign = [vname, ' = ', strtrim(s), ';'];
end

% Convert to C format (simple version - assumes vector)
s_c = sym2c(char(A));
if max(nr, nc) > 1
  c_assign = sprintf("double %s[%d] = {%s};", vname, max(nr, nc), s_c);
else
  c_assign = sprintf("double %s = %s;", vname, s_c);
end
end


function c_str = sym2c(m_str)
% Convert MATLAB symbolic expression to C code
c_str = m_str;
% Replace MATLAB operators with C equivalents
c_str = strrep(c_str, '^', 'pow');  % Simplified - would need more complex handling
c_str = regexprep(c_str, '(\w+)\s*pow', 'pow($1,');  % Fix pow format
c_str = strrep(c_str, 'i', 'I');  % imaginary unit
end