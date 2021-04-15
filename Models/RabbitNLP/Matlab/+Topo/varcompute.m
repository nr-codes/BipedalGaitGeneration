function [t, sol, error] = varcompute(sol, nlp, tol)

% compute prop based on nlp property and not phase

% CHANGELOG:
%   3/22/2021 - Copied from Nlp/compileConstraint; modified for use with
%   topo code.

if nargin < 1
    sol = evalin('base', 'sol');
end

if nargin < 2
    nlp = evalin('base', 'nlp');
end

prop = 'VariableArray';

if nargin < 4
    tol = 10^-10;
end

v = nlp.(prop);

n = max(vertcat(v.Indices));
name = cell(n, 1);

for i = 1:length(v)
    vi = v(i);
    ij = vi.Indices;
    namefun = @(ii) sprintf('%d| %s', ii, vi.Name);
    name(ij) = arrayfun(namefun, ij, 'UniformOutput', false);
end

l = vertcat(v.LowerBound);
u = vertcat(v.UpperBound);
i = vertcat(v.InitialValue);
b = repmat('✗', n, 1);
b((l - sol <= tol) & (sol - u <= tol)) = '✓';

t = table(i, sol, l, u, b, ...
    'RowNames', name, 'VariableNames', {'i', 'v', 'l', 'u', '?'});

error = sol - max(min(sol, u), l);
end