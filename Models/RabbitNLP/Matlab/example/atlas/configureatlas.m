function T = configureatlas(usefrost)
% CHANGELOG:
%   4/14/2021 - Yanked out functions from LoadModel and AtlasModel to make
%   computation of dynamics steps explicit.

%% robot model settings
cur = fileparts(mfilename);
addpath(genpath(cur));

urdf = fullfile(cur,'urdf','Atlas.urdf');

% specify the path to the FROST
addpath('../../');
frost_addpath;


base = get_base_dofs('floating');

limits = [base.Limit];

[limits.lower] = deal(-0.6, -0.2, 0.7, -0.1, -0.5, -0.1);
[limits.upper] = deal(0.3, 0.2, 1.0, 0.1, 0.5, 0.1);
[limits.velocity] = deal(1, 0.1, 0.5, 0.5, 0.5, 0.5);
[limits.effort] = deal(0);
for i=1:6
    base(i).Limit = limits(i);
end

[name, links, joints, ~] = ros_load_urdf(urdf);

if(nargin > 0 && usefrost)
    % match the default set of links and joints used in FROST's example/atlas
    j = startsWith({joints.Name}, {'back', 'l_leg', 'r_leg'});
    l = matches({links.Name}, unique({joints(j).Parent, joints(j).Child}));
else
    % configure all links
    j = 1:numel(joints);
    l = 1:numel(links);
end

config.name = name;
config.joints = joints(j);
config.links = links(l);


delay_set = false; % not going to compile to C, so evaluate c(q, qd) in MMA
omit_coriolis = false; % we want h(q, qd) = c(q, qd) + g(q)


atlas = RobotLinks(config, base);
%%%%%%%%%%%%%%%%%% time it
tic;

configureDynamics(atlas, 'DelayCoriolisSet', delay_set, ...
    'OmitCoriolisSet', omit_coriolis);

T = toc;
%%%%%%%%%%%%%%%%%% time it
end