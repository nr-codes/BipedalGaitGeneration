function l = tolist(varargin)
l = cell(size(varargin));
for i = 1:length(l)
    l{i} = char(varargin{i});
end
l = ['{', strjoin(l, ', '), '}'];
end