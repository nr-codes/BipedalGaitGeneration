function s = num2mathstr(x, varargin)
        
    if isinf(x)
        if x < 0
            s = '-Infinity';
        else
            s = 'Infinity';
        end
    elseif isequal(fix(x),x) % integer
        s = num2str(x);
    else
        % x = roundn(x,-9);
        s = num2str(x,'%.6f');
    end
end

% CHANGELOG:
%   3/24/2021 - Fixed bug with -Inf mapping to Infinity instead of
%   -Infinity