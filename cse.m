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

% Extract powers of symbolic variables FIRST (before CSE loop)
symvars = symvar(r);
for k = 1:length(symvars)
  base = symvars(k);
  % Find maximum power by checking which powers appear
  max_pwr = 1;
  dummy = sym('__dummy__');  % Unique symbol to avoid division by zero
  for pwr = 2:10
    if ~isequal(r, subs(r, base^pwr, dummy))
      max_pwr = pwr;
    end
  end
  % Extract each power from 2 to max_pwr
  for pwr = 2:max_pwr
    pwr_name = sprintf('%s_%d', char(base), pwr);
    % Use lower power if available, otherwise compute from base
    if pwr == 2
      power_expr = base * base;
      m_expr_str = sprintf('%s*%s', char(base), char(base));  % Format as a*a
    else
      prev_pwr_name = sprintf('%s_%d', char(base), pwr-1);
      power_expr = sym(prev_pwr_name) * base;
      m_expr_str = sprintf('%s*%s', prev_pwr_name, char(base));  % Format as a_2*a
    end
    m_lines(end+1) = sprintf('%s = %s;', pwr_name, m_expr_str);
    [c_type, c_expr] = analyzeCCode(ccode(power_expr));
    c_lines(end+1) = sprintf("%s %s = %s;", c_type, pwr_name, c_expr);
    r = subs(r, base^pwr, sym(pwr_name));
    defs.(pwr_name) = power_expr;
  end
end

% Iteratively extract common subexpressions
for i = 1:ncse
  sstr = sprintf('%s%d', tmp_name, i);
  [r_new, sigma] = subexpr(r, sstr);
  if isempty(sigma), break; end  % No more subexpressions found
  
  % Format MATLAB and C assignments
  sigma_str = char(sigma);
  m_lines(end+1) = sprintf('%s = %s;', sstr, sigma_str);
  [c_type, c_expr] = analyzeCCode(ccode(sigma));
  c_lines(end+1) = sprintf("%s %s = %s;", c_type, sstr, c_expr);
  
  defs.(sstr) = sigma;  % Store definition
  r = r_new;  % Update expression with substitution
end

% Get caller's variable name or use default
vname = inputname(1); 
if isempty(vname), vname = 'r'; end

% Determine result array type based on whether any temp is complex
is_complex = any(contains(c_lines, 'double _Complex'));
if is_complex
  result_c_type = 'double _Complex';
else
  result_c_type = 'double';
end

% Format final result assignment
[m_assign, c_assign] = formatAssignment(r, vname, result_c_type);
m_lines(end+1) = m_assign;
c_lines(end+1) = c_assign;

% Combine all lines into output code strings
m_code = strjoin(m_lines, newline);
c_code = strjoin(c_lines, newline);

end


function [c_type, c_expr] = analyzeCCode(c_expr)
% Analyze C expression: determine type (double or double _Complex), clean expression
c_expr = regexprep(c_expr, '^\s*\w+\s*=\s*', '');  % Remove "t0 = "
c_expr = regexprep(c_expr, ';+\s*$', '');           % Remove trailing semicolons
c_expr = regexprep(c_expr, '(\d+\.?\d*)\*?i\b', '$1*I');  % Convert 2i to 2*I

% Check if expression contains imaginary unit
if contains(c_expr, '*I') || contains(c_expr, 'sqrt(-1')
    c_type = 'double _Complex';
else
    c_type = 'double';
end
end


function [m_assign, c_assign] = formatAssignment(A, vname, result_c_type)
% Format assignment statement for MATLAB and C
% Input: A = symbolic matrix/value, vname = variable name, result_c_type = 'double' or 'double _Complex'
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

% Convert to C format
if max(nr, nc) > 1
    % Matrix/vector: generate indexed assignments
    c_lines = string([]);
    c_lines(end+1) = sprintf("%s %s[%d];", result_c_type, vname, max(nr, nc));
    for j = 1:max(nr, nc)
        [~, c_expr] = analyzeCCode(ccode(A(j)));
        c_lines(end+1) = sprintf("%s[%d] = %s;", vname, j-1, c_expr);
    end
    c_assign = strjoin(c_lines, newline);
else
    % Scalar
    [c_type, c_expr] = analyzeCCode(ccode(A));
    c_assign = sprintf("%s %s = %s;", c_type, vname, c_expr);
end
end
