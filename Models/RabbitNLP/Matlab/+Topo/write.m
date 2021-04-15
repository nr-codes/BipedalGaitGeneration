function file = write(nlp, file, x)
% assumption in FROST (which should be formalized maybe...) is that
% constraints with the same name can be converted into a function once and
% then called with different parameters.  we could do this to speed up the
% processing.

if nargin < 1
    nlp = evalin('base', 'nlp');
end

if nargin < 2
    fid = 1;
    file = 'stdout';
else
    fid = fopen(file,'w');
end

if nargin < 3
    x = [];
end

funcs = {'VariableArray', 'ConstrArray', 'CostArray'};

fprintf(fid, '(* ::Chapter:: *)\n');
fprintf(fid, '(*%s*)\n', nlp.Name);
fprintf(fid, '(* ::Package:: *)\n');
fprintf(fid, 'BeginPackage["Frost`"];\n');
fprintf(fid, '%s::usage = "";\n', funcs{:});
fprintf(fid, 'Begin["`Private`"];\n');

fprintf(fid, '(* ::Section:: *)\n');
fprintf(fid, '(*Variable Array*)\n');
fprintf(fid, '(* ::Text:: *)\n');
fprintf(fid, '(*{Name, InitialValue, LowerBound, UpperBound, Indices}*)\n');

array = strjoin(Topo.convertvar(nlp), [',', newline]);
fprintf(fid, 'VariableArray[Array] = {\n%s\n};\n', array);

fprintf(fid, '(* ::Section:: *)\n');
fprintf(fid, '(*Variable Solution*)\n');

array = Topo.str(transpose(x));
fprintf(fid, 'VariableArray[N] = %s\n};\n', array(1:end-1));

fields = {'ConstrArray', 'CostArray'};
for i = 1:length(fields)
    f = fields{i};
    [array, funcs, map] = Topo.convertfunc(nlp, f);
    
    fprintf(fid, '(* ::Section:: *)\n');
    fprintf(fid, '(*%s Array*)\n', f);
    fprintf(fid, '(* ::Text:: *)\n');
    fprintf(fid, '(*{Name, Type, LowerBound, UpperBound, FuncIndices}*)\n');
    
    fprintf(fid, '%s[Array] = {\n%s\n};\n', f, ...
        strjoin(array, [',', newline]));
    
    fprintf(fid, '(* ::Section:: *)\n');
    fprintf(fid, '(*%s Functions*)\n', f);
    
    fprintf(fid, strjoin(funcs.values, newline));
    fprintf(fid, '\n');
    
    fprintf(fid, '(* ::Section:: *)\n');
    fprintf(fid, '(*%s Map*)\n', f);
    fprintf(fid, '(* ::Text:: *)\n');
    fprintf(fid, '(*{Name, DepVariables.Indices, ');
    fprintf(fid, 'pind, AuxData, FuncIndices}*)\n');
    
    fprintf(fid, '%s[Map] = {\n%s\n};\n', f, ...
        strjoin(map, [',', newline]));
end

fprintf(fid, '\n\n'); % 2 blank lines to start new cell
fprintf(fid, 'End[];\n');
fprintf(fid, 'EndPackage[];');

if nargin > 1
    fclose(fid);
end
end