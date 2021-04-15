function [x, t, xdot] = to(x, t, xdot, old)
% TO Convert to/from topo to frost coordinate system
%   X = TO(X) Returns state X from topo/frost coordinates to frost/topo
%   coordinates.
%
%   X = TO(X, T) Same as above, but also pass time information when the
%   input X is in frost coordinates.
%
%   [X, T] = TO(__) Same as above, but also return time information.

if nargin < 1
    nlp = evalin('base', 'nlp');
    sol = evalin('base', 'sol');
    [t, x] = nlp.exportSolution(sol);
    t = t{1};
    xdot = [x{1}.dx; x{1}.ddx];
    x = [x{1}.x; x{1}.dx];
end

if nargin < 4
    % we have two different rabbit models, original coords is old
    % frost-like coords is new (only indices are different)
    old = false;
end

[n, k] = size(x);


if mod(n, 8) == 0
    % we have a topo mma configuration convert to frost coordinates
    nq = 8;
    i = [2 3 4 6 8 5 7];
    m = [1; 1; -1; -1; -1; -1; -1];
    b = [0; 0; 0; pi; 0; pi; 0];
    t = x(:,1); % phase variable
    
    theta = []; % no phase variable
    dtheta = [];
    ddtheta = [];
else
    % we have a frost mb configuration convert to topo coordinates
    nq = 7;
    if old
        i = [1 2 3 6 4 7 5];
        m = [1; 1; -1; -1; -1; -1; -1];
        b = [0; 0; 0; pi; pi; 0; 0];
    else
        i = [1 2 3 4 6 5 7];
        m = ones(nq, 1);
        b = zeros(nq, 1);
    end
    
    if nargin > 0 && nargin < 2
        t = zeros(1, k); % phase variable
    elseif isscalar(t)
        t = linspace(0, t, k);
    end
    
    theta = t; % phase variable
    dtheta = ones(size(t));
    ddtheta = zeros(size(t));
end

q = [theta; b + m .* x(i, :)];

if n > nq
    qdot = [dtheta; m .* x(i + nq, :)];
else
    qdot = []; 
end

x = [q; qdot];

if nargout >= 3
    qddot = [ddtheta; m .* xdot(i + nq, :)];
    xdot = [qdot; qddot];
end

end