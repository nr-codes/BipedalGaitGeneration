% build_mex(...
%     '/home/nr/Documents/Tex/BipedalGaitGeneration/Repo/Models/RabbitNLP/Matlab/example/rabbit/gen/opt', ...
%     'fRightToe_vec_RightStance');


% sol = [0.,0.25,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,313.92,0.,0.,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,0.25,0.,0.,0.25,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,313.92,0.,0.,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,0.25,0.,0.,0.25,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,313.92,0.,0.,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,0.25,0.,0.,0.25,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,313.92,0.,0.,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,0.25,0.,0.,0.25,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,313.92,0.,0.,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,3.14159,0.,0.25,0.,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.8,0.,3.14159,0.,3.14159,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.,0.]';

x = sol;
c = nlp.ConstrArray;

clear f b;

n = max([c.FuncIndices]);
f(n, 1) = 0;
name = cell(n, 1);

i = 6;
ci = c(i).getSummands();

b(n, 1) = 0;

for j = 1:length(ci)
    cj = ci(j);
    fj = cj.Funcs.Func;
    xj = {cj.DepVariables.Indices};
    xj = arrayfun(@(ii) x(ii{:}), xj, 'UniformOutput', false);
    dj = cj.AuxData;
    ij = cj.FuncIndices;
    
    namefun = @(ii) sprintf('%d| %s', ii, c(i).Name);
    name(ij) = arrayfun(namefun, ij, 'UniformOutput', false);
%     cj.Name

    a = cj.SymFun.Vars{1};
    for k = 2:length(cj.SymFun.Vars)
        a = vertcat(a, cj.SymFun.Vars{k});
    end
        
    if isempty(dj)
%         cj.DepVariables.Name
%         cj.DepVariables.Dimension
%         cj.DepVariables.Indices
        feval(fj, xj{:});
        sprintf('%1.16f\n', feval(fj, xj{:}));
        f(ij) = f(ij) + feval(fj, xj{:});
        b(ij) = b(ij) + cj.SymFun.subs(a, vertcat(xj{:})).double;
    else
        feval(fj, xj{:}, dj{:});
        sprintf('%1.16f\n', feval(fj, xj{:}, dj{:}));
        f(ij) = f(ij) + feval(fj, xj{:}, dj{:});
        b(ij) = b(ij) + cj.SymFun.subs(a, vertcat(xj{:}), vertcat(dj{:})).double;
    end
end

% cj.SymFun.subs([cj.SymFun.Vars, cj.SymFun.Params], xj)
% b = cj.SymFun.subs(a, vertcat(xj{:}));

sprintf('%1.16f\n', f(ij))
sprintf('%1.16f\n', b(ij));

[f(ij) b(ij)]

norm(f(ij))
norm(b(ij))

% cur = what('Topo').path;
% 
% model_path = fullfile(cur, '../../../');
% repo_path = fullfile(model_path, '../');
% 
% 
% if ispc
%     % For windows, use ''/' instead of '\'. Otherwise mathematica does
%     % not recognize the path.
%     model_path = strrep(model_path,'\','/');
%     repo_path = strrep(repo_path,'\','/');
% end
%     
% math(['$Path=DeleteDuplicates[Append[$Path,',str2mathstr(repo_path),']];']);
% math(['$Path=DeleteDuplicates[Append[$Path,',str2mathstr(model_path),']];']);
% 
% math('Get["SIMple`"];')
% eval_math('Z3')
% math('Get["RabbitNLP`"]')
%     
%     eval_math('Needs["RobotManipulator`"];');
% 
% 
% math('Print["Hello"]')