function m = tofunc(prop, name, f, v, p)
[vmat, vmath] = Topo.parse(v, '#1');
[pmat, pmath] = Topo.parse(p, '#2');

% replace is first match and done, so sort such that longer strings are
% earlier than shorter substrings
mat = [vmat, pmat];
math = [vmath, pmath];
[~, i] = sort(mat);
i = i(end:-1:1);

f = char(f);
body = replace(f, mat(i), math(i));
m = sprintf('%s["%s"] = %s&;', prop, name, body);
end