function index = prettyprint(nlp, lines, dir)
% PRETTYPRINT Prints the nonlinear problem in a nice format

if nargin < 1
    nlp = evalin('base', 'nlp');
end

if nargin < 2
    lines = 50;
end

if nargin < 3
    dir = 'html';
end

% get the main parts of an NLP
obj = printobjective(nlp.CostArray);
var = printvariables(nlp.VariableArray);
cons = printconstraints(nlp.ConstrArray);

out = [
%     {'\text{min}:', '', '', ''};
%     obj;
    {'\text{s.t.}:', '', '', ''};
    cons
%     {'\text{w.r.t}:', '', '', ''};
%     var;
    ];

% latexify the source

% to aggressive of a replace
% v = {nlp.VariableArray.Name, nlp.ConstrArray.Name, nlp.CostArray.Name};
% pat = {'Inf', '*', 'Cos', 'Sin', ['(', strjoin(v, '|'), ')']};
% rep = {'\\infty', ' ', '\\cos', '\\sin', '\\texttt{$1}'};
pat = {'Inf', '*', 'Cos', 'Sin', '_'};
rep = {'\\infty', ' ', '\\cos', '\\sin', '\\_'};
out = regexprep(out, pat, rep);

% line wrap long statements
% k = 0;
% linewrap = 72;
% for i = 1:size(out, 1)
%     o = {};
%     [a, b, c, d] = out{i + k, :};
%     if strlength(b) > linewrap || strlength(c) > linewrap
%         while strlength(b) > 0 || strlength(c) > 0
%             if strlength(b) > linewrap
%                 bb = b(1:72);
%                 b = b(73:end);
%             else
%                 bb = b;
%                 b = '';
%             end
%             if strlength(c) > linewrap
%                 cc = c(1:72);
%                 c = c(73:end);
%             else
%                 cc = c;
%                 c = '';
%             end
%             
%             o(end+1, :) = {a, bb, cc, d}; %#ok<AGROW>
%         end
%         
%         out = [out(1:i + k - 1, :); o; out(i + k + 1:end, :)];
%         k = k + size(o, 1) - 1;
%     end
% end

latex = cell(size(out, 1), 1);
for i = 1:size(out, 1)
    latex{i} = sprintf('%s & \\quad & %s & %s & \\quad & %s \\\\', out{i, :});
end

% output to html files
if ~isfolder(dir)
    mkdir(dir);
end

n = 0:lines:size(latex, 1);
if n(end) ~= size(latex, 1)
    n(end + 1) = size(latex, 1);
end

files = cell(length(n) - 1, 1);
for i = 2:length(n)
    template = mathjaxtemplate(latex(n(i-1) + 1:n(i)));
    files{i-1} = [tempname(dir), '.html'];
    fid = fopen(files{i-1}, 'w');
    fwrite(fid, sprintf('%s\n', template{:}));
    fclose(fid);
end

index = ['index', '.html'];
fid = fopen(index, 'w');
template = indextemplate(files);
fwrite(fid, sprintf('%s\n', template{:}));
fclose(fid);
end

% -------------------------------------------------------------------

function out = printobjective(nlpFunc)
out = printfunctions(nlpFunc, false, '');
end

% -------------------------------------------------------------------

function out = printconstraints(nlpFunc)
out = printfunctions(nlpFunc, true, '');
end

% -------------------------------------------------------------------

function out = printvariables(nlpVar)
out = {};
for i = 1:length(nlpVar)
    n = printname(nlpVar(i));
    for j = 1:nlpVar(i).Dimension
        lb = nlpVar(i).LowerBound(j);
        ub = nlpVar(i).UpperBound(j);
        x0 = nlpVar(i).InitialValue(j);
        var = sprintf('%s[%d, %d]', n, i, j);
        out(end + 1, :) = printbounds(var, lb, ub, x0); %#ok<AGROW>
    end
end
end

% -------------------------------------------------------------------

function out = printfunctions(nlpFunc, printbnds, k)
out = {};
for i = 1:length(nlpFunc)
    func = nlpFunc(i);
    name = printname(func);
    
    process = {
        'y_time_RightStance'
        %'swing_foot_height';
        %'u_leftFootHeight_RightStance';
        };
    
    if all(~strcmp(name, process))
        continue;
    end
    
    if isempty(k)
        % i^th NlpFunction
        ind = num2str(i);
    else
        % a recursive call to compute nlpFunc(k).SummandFunctions
        ind = sprintf('%s, %d', k, i);
    end
    
    % print symbolic function
    m = length(func.SymFun);
    if m > 0
        % convert $d$e to [d, e] (see rep for fcn call)
        toarray = @(x) ['[', strrep(x(2:end), '$', ', '), ']']; %#ok<NASGU>
        % convert symfunc from mma list to latex output
        % get variable names
        pat = {'^{|}$', '(\$\d+)+'};
        rep = {'', '${toarray($1)}'};
        for j = 1:m
            symfunc = func.SymFun(j);
            % convert to latex expr
            s = regexprep(char(symfunc), pat, rep);
            if printbnds
                lb = func.LowerBound(j);
                ub = func.UpperBound(j);
                out(end + 1, :) = printbounds(s, lb, ub); %#ok<AGROW>
            else
                out(end + 1, :) = {'', '', s, ''}; %#ok<AGROW>
            end
            
            out{end, 1} = [ind, ', ', num2str(j), ':'];
            out{end, 4} = name;
        end
    end
    
    m = length([func.SummandFunctions]);
    if m > 0
        warning('integral has func.LowerBound and upper bounds too');
        out(end + 1, :) = {[ind, ':'], '\int', '', name}; %#ok<AGROW>
        for j = 1:m
            s = func.SummandFunctions(j);
            %out(end + 1:end + func.Dimension, :) = printfunctions(s, printbnds, ind);
            pf = printfunctions(s, printbnds, ind);
            out(end + 1:end + func.Dimension, :) = pf;
        end
    end
end
end

% -------------------------------------------------------------------

function out = printbounds(expr, lb, ub, x0)
if nargin < 4
    bnds = sprintf('\\in [%f, %f]', lb, ub);
else
    bnds = sprintf('= %f \\in [%f, %f]', x0, lb, ub);
end

out = {'', expr, bnds, ''};
end

% -------------------------------------------------------------------

function out = printname(nlpObj)
out = nlpObj.Name; % ['\texttt{', nlpObj.Name, '}'];
end

% -------------------------------------------------------------------

function template = indextemplate(files)
for i = 1:length(files)
    files{i} = sprintf('<p><a href="%s">page %d</a></p>', files{i}, i);
end

template = [
    {
    '<!DOCTYPE html>';
    '<html>';
    '<head>';
    '<title>FROST&#10052;&#65039; Nonlinear Programming Problem</title>';
    '</head>';
    '<body>';
    }
    files;
    {
    '</body>';
    '</html>'}];
end

% -------------------------------------------------------------------

function template = mathjaxtemplate(latex)
template = [
    {
    '<!DOCTYPE html>';
    '<html>';
    '<head>';
    '<title>FROST&#10052;&#65039;️Nonlinear Programming Problem</title>';
    '<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>';
    '<script type="text/javascript" id="MathJax-script" async';
    '  src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js">';
    '</script>';
    '</head>';
    '<body>';
    '\begin{alignat*}{3}'}
    latex;
    {
    '\end{alignat*}';
    '</body>';
    '</html>'}];
end

% -------------------------------------------------------------------

% function template = latextemplate(latex)
% need to replace _ with \_ to avoid compilation errors
% out = ['\texttt{', strrep(nlpObj.Name, '_', '\_'), '}'];
% template = [
%     {
%     '\documentclass[10pt]{article}';
%     '\usepackage{amsmath}';
%     '\pagestyle{empty}';
%     '\begin{document}';
%     '\begin{alignat*}{3}';
%     };
%     latex;
%     {
%     '\end{alignat*}';
%     '\end{document}'
%     }
%     ];
% end