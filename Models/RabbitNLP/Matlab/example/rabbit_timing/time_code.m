clear; clc;

if isfolder('./gen')
    rmdir './gen' s
end

addpath('../../');
frost = frost_addpath;
rabbitpath = fullfile(frost, 'example', 'rabbit');
addpath(genpath(rabbitpath));

scriptstart = tic;
main_opt;
scriptstop = toc(scriptstart);

codegenstop
scriptstop