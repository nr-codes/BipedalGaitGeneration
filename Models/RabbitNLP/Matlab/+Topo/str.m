function s = str(X, var)

if nargin < 2
    v = '';
    e = '';
else
    v = [var, ' = '];
    e = [';', newline];
end

s = size(X);
s(1) = 1;
s = repmat({'%1.16g'}, s);

s = sprintf(['{ ', strjoin(s, ', '), ' },', newline], X');
s = s(1:end-2); % drop trailing comma and newline;
s = strrep(s, 'e', '*^');
s = sprintf(['%s{', newline, '%s}%s'], v, s, e);
end