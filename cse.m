
function [m_code, c_code] = cse(r, tmp_name, ncse, max_power)
% Common subexpression elimination (CSE) - extracts repeated expressions as temporary variables
% Input: 
%        r         = symbolic expression(s)
%        tmp_name  = prefix for temp vars, optional, default: 'tmp'
%        ncse      = max CSE iterations, optional, default: 10
%        max_power = max power to extract as separate symbols, optional, default: 10
% Output: 
%        m_code = MATLAB code string with all assignments
%        c_code = C code string equivalent

% -------------------------------------------------------------------------
% Default parameter values
% -------------------------------------------------------------------------
if nargin < 2 || isempty(tmp_name),  tmp_name  = 'tmp'; end
if nargin < 3 || isempty(ncse),      ncse      = 10;    end
if nargin < 4 || isempty(max_power), max_power = 10;    end

% -------------------------------------------------------------------------
% Convert input to symbolic if needed
% -------------------------------------------------------------------------
if ischar(r) || isstring(r)
  r = str2sym(r);
end

% Handle cell array input by converting to symbolic column vector
if iscell(r)
  r = cellfun(@str2sym, r, 'UniformOutput', false);
  r = vertcat(r{:});
end

% Simplify
r = simplify(collect(r));

% -------------------------------------------------------------------------
% Initialize code buffers
% -------------------------------------------------------------------------
m_lines = string([]);
c_lines = string([]);

% -------------------------------------------------------------------------
% 1) Extract powers of symbolic variables BEFORE CSE loop
% -------------------------------------------------------------------------
[r, m_lines, c_lines] = extractPowers(r, m_lines, c_lines, max_power);

% -------------------------------------------------------------------------
% 2) Iteratively extract common subexpressions (CSE)
% -------------------------------------------------------------------------
[r, m_lines, c_lines] = performCSE(r, m_lines, c_lines, tmp_name, ncse);

% -------------------------------------------------------------------------
% 3) Final result assignment
% -------------------------------------------------------------------------
% Get caller's variable name or use default
vname = inputname(1); 
if isempty(vname), vname = 'r'; end

% Determine result array type based on temps AND final expression
is_complex_temp = any(contains(c_lines, 'double _Complex'));
c_type_result   = 'double';
try
    [c_type_result, ~] = analyzeCCode(ccode(r));
catch
    % If ccode(r) fails for some composite type, fall back to temps only
end

is_complex = is_complex_temp || strcmp(c_type_result, 'double _Complex');

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

% =====================================================================
% Helper: extractPowers
% =====================================================================
function [r_out, m_lines, c_lines] = extractPowers(r_in, m_lines, c_lines, max_power)
r = r_in;
symvars = symvar(r);

for k = 1:numel(symvars)
    base = symvars(k);

    % Find maximum power actually present in r for this base
    max_pwr_found = 1;
    for pwr = 2:max_power
        if has(r, base^pwr)           % <-- key change
            max_pwr_found = pwr;
        end
    end

    % No powers of this base present -> skip
    if max_pwr_found == 1
        continue;
    end

    % Extract each power from 2 to max_pwr_found
    for pwr = 2:max_pwr_found
        pwr_name = sprintf('%s_%d', char(base), pwr);

        % Use lower power if available, otherwise compute from base
        if pwr == 2
            power_expr = base * base;
            m_expr_str = sprintf('%s*%s', char(base), char(base));        % a*a
        else
            prev_pwr_name = sprintf('%s_%d', char(base), pwr-1);
            power_expr = sym(prev_pwr_name) * base;
            m_expr_str = sprintf('%s*%s', prev_pwr_name, char(base));     % a_2*a
        end

        % MATLAB assignment
        m_lines(end+1) = sprintf('%s = %s;', pwr_name, m_expr_str);

        % C assignment
        [c_type, c_expr] = analyzeCCode(ccode(power_expr));
        c_lines(end+1) = sprintf('%s %s = %s;', c_type, pwr_name, c_expr);

        % Substitute in main expression
        r = subs(r, base^pwr, sym(pwr_name));
    end
end

r_out = r;
end

% =====================================================================
% Helper: performCSE
% =====================================================================
function [r_out, m_lines, c_lines] = performCSE(r_in, m_lines, c_lines, tmp_name, ncse)
r = r_in;

for i = 1:ncse
  sstr = sprintf('%s%d', tmp_name, i);
  [r_new, sigma] = subexpr(r, sstr);
  if isempty(sigma), break; end  % No more subexpressions found

  % MATLAB assignment
  sigma_str = char(sigma);
  m_lines(end+1) = sprintf('%s = %s;', sstr, sigma_str);

  % C assignment
  [c_type, c_expr] = analyzeCCode(ccode(sigma));
  c_lines(end+1) = sprintf('%s %s = %s;', c_type, sstr, c_expr);

  % Update expression with substitution
  r = r_new;
end

r_out = r;
end

% =====================================================================
% Helper: analyzeCCode
% =====================================================================
function [c_type, c_expr] = analyzeCCode(c_expr)
% Analyze C expression: determine type (double or double _Complex), clean expression

% Remove leading temp assignment (e.g. "t0 =")
c_expr = regexprep(c_expr, '^\s*\w+\s*=\s*', '');

% Remove trailing semicolons
c_expr = regexprep(c_expr, ';+\s*$', '');

% Normalize MATLAB-style imaginary literals to C's I
% Handles "2i", "2*i", "2 * i"
c_expr = regexprep(c_expr, '(\d+\.?\d*)\s*\*?\s*i\b', '$1*I');

% Bare "i" (not part of an identifier) -> "I"
c_expr = regexprep(c_expr, '(?<![A-Za-z0-9_])i\b', 'I');

% Check for complex usage
if contains(c_expr, 'I')          || ...
   contains(c_expr, 'sqrt(-1')    || ...
   contains(c_expr, 'creal(')     || ...
   contains(c_expr, 'cimag(')
    c_type = 'double _Complex';
else
    c_type = 'double';
end
end

% =====================================================================
% Helper: formatAssignment
% =====================================================================
function [m_assign, c_assign] = formatAssignment(A, vname, result_c_type)
% Format assignment statement for MATLAB and C
% Input:  A = symbolic matrix/value
%         vname = variable name
%         result_c_type = 'double' or 'double _Complex'
% Output: m_assign = MATLAB assignment string
%         c_assign = C assignment string

[nr, nc] = size(A);
numelA   = nr * nc;

% ---------------------------------------------------------------------
% MATLAB assignment formatting (no evalc/disp)
% ---------------------------------------------------------------------
if numelA > 1
    rows = strings(nr, 1);
    for i = 1:nr
        elems = strings(1, nc);
        for j = 1:nc
            elems(j) = char(A(i, j));
        end
        rows(i) = strjoin(elems, ', ');
    end

    nl = newline;
    ml = strings(0, 1);
    ml(end+1) = vname + " = [ ...";
    for i = 1:nr
        if i < nr
            ml(end+1) = "  " + rows(i) + "; ...";
        else
            ml(end+1) = "  " + rows(i);
        end
    end
    ml(end+1) = "];";
    m_assign = strjoin(ml, nl);
else
    % Scalar
    m_assign = sprintf('%s = %s;', vname, char(A));
end

% ---------------------------------------------------------------------
% C assignment formatting
% ---------------------------------------------------------------------
if numelA > 1
    % Matrix/vector: generate flat 1-D array with linear indexing
    n_elements = numelA;
    c_lines = strings(0, 1);

    % Declaration
    c_lines(end+1) = sprintf('%s %s[%d];', result_c_type, vname, n_elements);

    % Assign each element using column-major linear indexing (A(:))
    for idx = 1:n_elements
        [~, c_expr] = analyzeCCode(ccode(A(idx)));
        c_lines(end+1) = sprintf('%s[%d] = %s;', vname, idx-1, c_expr);
    end

    c_assign = strjoin(c_lines, newline);
else
    % Scalar
    [c_type_elem, c_expr] = analyzeCCode(ccode(A));

    % If any temps or caller requested complex, or expression itself is complex,
    % use complex; otherwise, use double.
    if strcmp(result_c_type, 'double _Complex') || strcmp(c_type_elem, 'double _Complex')
        final_type = 'double _Complex';
    else
        final_type = 'double';
    end

    c_assign = sprintf('%s %s = %s;', final_type, vname, c_expr);
end

end
