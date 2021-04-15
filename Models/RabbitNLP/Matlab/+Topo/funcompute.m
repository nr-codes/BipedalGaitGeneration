function [t, f, error] = funcompute(x, nlp, prop, tol)

% compute prop based on nlp property and not phase

% CHANGELOG:
%   3/22/2021 - Copied from Nlp/compileConstraint; modified for use with
%   topo code.

if nargin < 1
    x = evalin('base', 'sol');
end

if nargin < 2
    nlp = evalin('base', 'nlp');
end

if nargin < 3
    prop = 'ConstrArray';
end

if nargin < 4
    tol = 10^-10;
end

c = nlp.(prop);

n = max([c.FuncIndices]);
f(n, 1) = 0;
name = cell(n, 1);

for i = 1:length(c)
    ci = c(i).getSummands();
    for j = 1:length(ci)
        cj = ci(j);
        fj = cj.Funcs.Func;
        xj = {cj.DepVariables.Indices};
        xj = arrayfun(@(ii) x(ii{:}), xj, 'UniformOutput', false);
        dj = cj.AuxData;
        ij = cj.FuncIndices;
        
        namefun = @(ii) sprintf('%d| %s', ii, c(i).Name);
        name(ij) = arrayfun(namefun, ij, 'UniformOutput', false);
        if isempty(dj)
            f(ij) = f(ij) + feval(fj, xj{:});
        else
            f(ij) = f(ij) + feval(fj, xj{:}, dj{:});
        end
    end
end

l = vertcat(c.LowerBound);
u = vertcat(c.UpperBound);
b = repmat('✗', n, 1);
b((l - f <= tol) & (f - u <= tol)) = '✓';

t = table(f, l, u, b, ...
    'RowNames', name, 'VariableNames', {'f', 'l', 'u', '?'});

error = f - max(min(f, u), l);
end