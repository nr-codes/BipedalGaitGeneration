function v = tovar(c, fn)
v = cellfun(@(x) flatten(x), c.SymFun.(fn), 'UniformOutput', false);
if isempty(v)
    v = SymExpression('{}');
else
    v = {[v{:}]};
    v = tovector(v{:});
end
end