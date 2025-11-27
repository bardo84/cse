function cse(r,tmp_name,ncse)
% Common subexpression elimination
if nargin < 2
  tmp_name = 'tmp'; % tmp1, tmp2, ...
end
if nargin < 3
  ncse = 10;
end
if nargin == 0
  expr = str2sym('a*x^3 + b*x^2 + c*x + d == 0');
  r = solve(expr, sym('x'), 'MaxDegree', 3)
  %r = str2sym('sin(x + y) + cos(x + y)');
  cse(r,'tmp',4);
  return
end
if ~isa(r, 'sym')
  r = str2sym(r);
end
for i = 1:ncse
  sstr = sprintf('%s%d',tmp_name,i);
  [r,sigma] = subexpr(r, sstr);
  if isempty(sigma)
    break
  end
  fprintf('%s = %s;\n', sstr, char(sigma))
end
inputForm(r, inputname(1));

function inputForm(A, vname)
% print vname = A as Matlab code
if nargin == 0
  A = randn(8);
  vname = 'A';
end
nl = newline;
s = evalc('disp(A)');
[nr, nc] = size(A);
if max(nr, nc) > 1
  s = strrep(s, '[', '');
  s = strrep(s, ']', '');
  s = strrep(s, nl, ['; ...', nl]);
  s = regexprep(s, '; \.\.\.\s*$', '');
  s = [vname, ' = [ ... ', nl, s, '];'];
else
  s = [vname, ' = ', strtrim(s), ';'];
end
disp(s)