function n = toexpression(varargin)
n = tovector(SymExpression(vertcat(varargin{:})));
end
