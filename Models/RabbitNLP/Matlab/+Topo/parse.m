function [vmat, vmath] = parse(v, c)
if isempty(v)
    vmat = [];
    vmath = [];
else
    vmat = strsplit(erase(char(v), {'{', '}', ' '}), ',');
    if nargout > 1
        for i = length(vmat):-1:1
            vmath{i} = [c, '[[', int2str(i), ']]'];
        end
    end
end
end