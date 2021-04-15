function [array, funcs, funcmap] = convertfunc(nlp, prop)

% convert nlp to code useful in mma package.

% CHANGELOG:
%   3/22/2021 - Copied from Nlp/compileConstraint; modified for use with
%   topo code.

import Topo.toexpression Topo.tovar Topo.tofunc Topo.tolist

%% limits
c = nlp.(prop);
n = length(c);
array{n} =  '';
for i = 1:n
    k = c(i).Name;
    array{i} = tolist( ...
        str2mathstr(k), ...
        str2mathstr(c(i).Type), ...
        toexpression(c(i).LowerBound), ...
        toexpression(c(i).UpperBound), ...
        toexpression(c(i).FuncIndices));
end

%% map
c = @(x) getSummands(x);
c = arrayfun(c, nlp.(prop), 'UniformOutput', false);
c = vertcat(c{:});

pi = 0;
n = length(c);
funcs = containers.Map('KeyType','char','ValueType','char');
funcmap{n} =  '';
for i = 1:n
    k = c(i).Name;
    f = toexpression(c(i).SymFun);
    v = tovar(c(i), 'Vars');
    p = tovar(c(i), 'Params');
    pind = pi + 1:pi + p.length;
    
    if ~funcs.isKey(k)
        funcs(k) = tofunc(prop, c(i).Name, f, v, p);
    end
    
    funcmap{i} = tolist( ...
        str2mathstr(k), ...
        toexpression(c(i).DepVariables.Indices), ...
        toexpression(pind), ...
        toexpression(c(i).AuxData), ...
        toexpression(c(i).FuncIndices));
    
    pi = pi + length(pind);
end
end