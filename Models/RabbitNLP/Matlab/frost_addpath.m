% CHANGELOG:
%   2/19/2021 - Added jsonlab to path
%   3/28/2021 - Made paths relative assuming in FrostModel

function frost = frost_addpath()

    % Add system related functions paths
    cur = fileparts(mfilename('fullpath'));

    if isempty(cur)
        cur = pwd;
    end 
    
    frost = fullfile(cur, '../../../Misc/frost');

    addpath(genpath(fullfile(frost, 'matlab')));
    addpath(fullfile(frost, 'matlab', 'nlp'));
    addpath(fullfile(frost, 'matlab', 'solver'));
    addpath(fullfile(frost, 'matlab', 'system'));
    addpath(fullfile(frost, 'matlab', 'control'));
    addpath(fullfile(frost, 'matlab', 'robotics'));
    % Add useful custom functions path
    addpath(fullfile(frost, 'matlab', 'utils'));
    addpath_matlab_utilities('general', 'mex', ...
        'graphics', 'mathlink', ...
        'sim', 'plot');

    % Add third party packages/libraries path
    addpath(fullfile(frost, 'third'));
    addpath_thirdparty_packages('GetFullPath', ...
        'mathlink', 'ipopt', 'sparse2', 'yaml', 'snopt');

    addpath(fullfile(frost, 'mathematica'));
    initialize_mathlink();

    addpath(fullfile(frost, 'example'));

    % warning('Restart Matlab to use the Snake yaml library.');
    % addpath(fullfile(cur, 'docs'));
    
    % we want to shadow a few of the default frost files
    addpath(fullfile(cur, 'example'));
    
    addpath(cur);
    
    for f = {'num2mathstr', 'frost_addpath'}
        assert(strcmp(which(f{:}), fullfile(cur, [f{:}, '.m'])));
    end
end 
