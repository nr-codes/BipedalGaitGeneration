function tohtml()

% CHANGELOG:
%   2/21/2021 - Added a conditional check for gen/sym instead of having to
%             uncomment/comment.
%
%             - Added a conditional check for gen/opt and gen/kinematics
%             instead of having to manually set COMPILE.
%
%             - Added BUG flag


%           Constraints                         Description
% {'tCont'                       }  interior vs cardinal time nodes
% {'timeDuration'                }  Tf - T0 (next impact time)
% {'pRightToeCont_RightStance'   }  stance position constraint location
% {'atimeCont_RightStance'       }  phase variable \theta(t) = (t-p(1))/(p(2)-p(1))
% {'ptimeCont_RightStance'       }  phase scaling to unit interval p(2), p(1)
% {'dynamics_equation'           }  M(x)\ddot{x} + ..., x => q
% {'h_RightToe_RightStance'      }  stance position constraint
% {'dh_RightToe_RightStance'     }  stance position constraint
% {'ddh_RightToe_RightStance'    }  stance position constraint
% {'u_friction_cone_RightToe'    }  stance position friction constraint
% {'y_time_RightStance'          }  VHCs for leg joints
% {'d1y_time_RightStance'        }  VHCs for leg joints
% {'d2y_time_RightStance'        }  VHCs for leg joints
% {'tau_0_RightStance'           }  phase constant value @ t = 0
% {'output_boundary_RightStance' }  keep angles w/i [-2*pi, 2*pi] (?)
% {'swing_foot_height'           }  swing foot height constraint @ t = 0 (?)
% {'u_leftFootHeight_RightStance'}  swing foot height internal @ t > 0
% {'tCont'                       }  interior vs cardinal time nodes
% {'pRightToeCont_RightStance'   }  stance position constraint location
% {'atimeCont_RightStance'       }  phase variable \theta(t) = (t-p(1))/(p(2)-p(1))
% {'ptimeCont_RightStance'       }  phase scaling to unit interval p(2), p(1)
% {'hs_int_x'                    }  hermite-simpson integration
% {'hs_int_dx'                   }  hermite-simpson integration
% {'dynamics_equation'           }  M(x)\ddot{x} + ..., x => q
% {'ddh_RightToe_RightStance'    }  stance position constraint
% {'u_friction_cone_RightToe'    }  stance position friction constraint
% {'d2y_time_RightStance'        }  VHCs for leg joints
% {'output_boundary_RightStance' }  keep angles w/i [-2*pi, 2*pi] (?)
% {'u_leftFootHeight_RightStance'}  swing foot height internal @ t > 0 (?)
% {'dynamics_equation'           }
% {'ddh_RightToe_RightStance'    }
% {'u_friction_cone_RightToe'    }
% {'d2y_time_RightStance'        }
% {'tau_F_RightStance'           }  phase constant value @ t = Tf
% {'output_boundary_RightStance' }
% {'average_velocity'            }  average velocity constraint
% {'u_leftFootHeight_RightStance'}  swing foot height internal @ t > 0
% {'xMinusCont_RightImpact'      }  impact map
% {'xPlusCont_RightImpact'       }  impact map
% {'dxMinusCont_RightImpact'     }  impact map
% {'dxPlusCont_RightImpact'      }  impact map
% {'dxDiscreteMapRightImpact'    }  impact map
% {'xDiscreteMapRightImpact'     }  impact map




%% Setup
clear; clc;
cur = pwd;
addpath(genpath(cur));

addpath('../../');
frost_addpath;
export_path = fullfile(cur, 'gen/');
% if load_path is empty, it will not load any expression.
% if non-empty and assigned valid directory, then symbolic expressions will
% be loaded  from the MX binary files from the given directory.

% load complains about y_time_RightStance; inspecting gen/sym should
% the library be searching for ya_time_RightStance or
% yd_time_RightStance instead?  Flag as bug for now.
BUG = 1;
if isfolder('gen/sym') && ~BUG
    load_path   = fullfile(cur, 'gen/sym');
else
    load_path   = [];
end

delay_set = false;
opt_path = [export_path, 'opt/'];
kin_path = [export_path,'kinematics/'];
COMPILE = ~isfolder(opt_path) || numel(dir(opt_path)) <= 2 || ...
    ~isfolder(kin_path) || numel(dir(kin_path)) <= 2;


% Load model
rabbit = RABBIT('urdf/five_link_walker.urdf');
if isempty(load_path)
    rabbit.configureDynamics('DelayCoriolisSet',delay_set);
else
    % load symbolic expression for the dynamics equations
    rabbit.loadDynamics(load_path, delay_set);
end


% Define domains
r_stance = RightStance(rabbit, load_path);
% l_stance = LeftStance(rabbit, load_path);
r_impact = RightImpact(r_stance, load_path);
% l_impact = LeftImpact(l_stance, load_path);

% Define hybrid system
rabbit_1step = HybridSystem('Rabbit_1step');
rabbit_1step = addVertex(rabbit_1step, 'RightStance', 'Domain', r_stance);

srcs = {'RightStance'};
tars = {'RightStance'};

rabbit_1step = addEdge(rabbit_1step, srcs, tars);
rabbit_1step = setEdgeProperties(rabbit_1step, srcs, tars, ...
    'Guard', {r_impact});

%% Define User Constraints
r_stance.UserNlpConstraint = str2func('right_stance_constraints');
r_impact.UserNlpConstraint = str2func('right_impact_constraints');

%% Define User Costs
u = r_stance.Inputs.Control.u;
u2r = tovector(norm(u).^2);
u2r_fun = SymFunction(['torque_' r_stance.Name],u2r,{u});

%% Create optimization problem
num_grid.RightStance = 1;
num_grid.LeftStance = 1;
nlp = HybridTrajectoryOptimization('Rabbit_1step',rabbit_1step,num_grid,[], ...
    'EqualityConstraintBoundary',1e-4, 'DerivativeLevel', 0);


% Configure bounds
setBounds;

% load some optimization related expressions here
if ~isempty(load_path) && ~BUG
    nlp.configure(bounds, 'LoadPath',load_path);
else
    nlp.configure(bounds);
end


% Add costs
addRunningCost(nlp.Phase(getPhaseIndex(nlp,'RightStance')),u2r_fun,'u');

% Update
nlp.update;


% save expressions after you run the optimization. It will save all required
% expressions
% do not need to save expressions if the model configuration is not
% changed. Adding custom constraints does not require saving any
% expressions.
% load_path = fullfile(cur, 'gen/sym');
% rabbit_1step.saveExpression(load_path);
%% Compile
if COMPILE
    if ~exist([export_path, 'opt/'], 'dir')
        mkdir([export_path, 'opt/'])
    end
    rabbit.ExportKinematics([export_path,'kinematics/']);
    compileConstraint(nlp,[],[],[export_path, 'opt/']);
    compileObjective(nlp,[],[],[export_path, 'opt/']);
end

% Example constraint removal
% removeConstraint(nlp.Phase(1),'u_friction_cone_RightToe');

%% Create Ipopt solver
addpath(genpath(export_path));
nlp.update;
% solver = IpoptApplication(nlp);

%%
prettyprint(nlp, 1000, '../gen/html')
end