function [c, x, p, u] = sol2math(nlp, sol, fid)
% SOL2TOMATH Convert from frost to topo coordinate system
%   X = SOL2TOMATH(NLP, SOL) Returns the NLP SOL in topo coordinates.
%
%   See also TO

if nargin < 1
    nlp = evalin('base', 'nlp');
end

if nargin < 2
    sol = evalin('base', 'sol');
end

if nargin < 3
    fid = 1;
end

[t, x, inputs, p] = nlp.exportSolution(sol);

t = t{1};
xdot = [x{1}.dx; x{1}.ddx];
x = [x{1}.x; x{1}.dx];
toe = p{1}.pRightToe([1,3]);
p = reshape(p{1}.atime, 4, 6);
u = inputs{1}.u;
f = inputs{1}.fRightToe;

p([2, 3],:) = p([3, 2],:);
[x, t, xdot] = Topo.to(x, t, xdot);

% i = 4:8;
% a = p(:, 3:4)';
% c = [x([i, i + 8], 1); a(:); t(end)];


% get full c vector
a = p';
c = [x(:,1); toe; a(:); t(end)];

if nargout == 0
    fprintf(fid, '%s', Topo.str(c, 'c'), Topo.str(x, 'x'), ...
        Topo.str(xdot, 'xdot'), Topo.str(p, 'p'), ...
        Topo.str(u, 'u'), Topo.str(f, 'f'));
end
end