function isit = istopo(x)
nq = 8;
isit = mod(size(x, 1), nq) == 0;
end