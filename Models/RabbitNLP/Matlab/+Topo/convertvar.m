function array = convertvar(nlp)

% convert nlp to code useful in mma package.

% CHANGELOG:
%   3/22/2021 - Copied from Nlp/compileConstraint; modified for use with
%   topo code.

import Topo.toexpression Topo.tolist

%% limits
c = nlp.('VariableArray');
n = length(c);
for i = n:-1:1
    k = c(i).Name;
    array{i} = tolist( ...
        str2mathstr(k), ...
        toexpression(c(i).InitialValue), ...
        toexpression(c(i).LowerBound), ...
        toexpression(c(i).UpperBound), ...
        toexpression(c(i).Indices));
end
end