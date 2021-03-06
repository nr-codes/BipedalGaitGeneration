(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



(* ::Input::Initialization:: *)
BeginPackage["BipedalLocomotion`CompassGaitWithTorso`", {"GlobalVariables`", "RigidBodyDynamics`", "BipedalLocomotion`", "BipedalLocomotion`Model`"}]

CompassGaitWithTorso::usage = "";
CompassGaitWithTorsoP::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
(* parameters *)
m = 5;
Mh = 15;
Mt = 15;
r = 1;
L = 1;
g = {0, 9.81, 0};

(* points of interest *)
torso = {0, L, 0};
foot = {0, -r, 0};
left = {"left leg", foot};
right = {"right leg", foot};

(* # of control/design parameters *)
n\[Mu] = 2;


(* ::Input::Initialization:: *)
(* pre-impact stance x[0-]/c- *)
stsw[s_, f_:{"left", "right"}] := If[StringMatchQ[s, "left", IgnoreCase->True], f, Reverse@f];


(* ::Input::Initialization:: *)
regopt[s_] := Module[{S},
S = stsw[s, {left, right}];
{"P" -> <|0 -> BLFeet[First@S, {4, 5}][1]|>, "S" -> S, "n\[Mu]" -> n\[Mu]}
];

cT[c_] := Module[{cT},
cT = c;
cT[[-3]] = -cT[[-3]];
cT
];


(* ::Input::Initialization:: *)
cm[s_, A_] := Module[{q, v, a, n, \[Theta]0T, C},
(* BLc indices *)
n = mm -1; (* 2D *)
{q, v} = Partition[BLIndices[BLGetBipedBase[], "p", "n" -> {\[DoubleStruckQ], \[DoubleStruckV]}], n];
q = "q" -> {q, Range@Length@q, 2A["np", s]};
v = "v" -> {v, Range@Length@v, A["np", s]};

(* polynomial scaling factors *)
\[Theta]0T = A["\[Theta]", s];

(* function specific parameters *)
a = <|"BLc" -> <|q, v|>, "BLc0T" -> <|"\[Theta]" -> \[Theta]0T|>, "BLSummary" -> <|"P" -> First@regopt[Last@stsw[s]]|>|>;

(* create parameters *)
C = BLContinuationParameters[Association -> a, "\[Mu]" -> n\[Mu], "c[T]" -> cT];

<|s -> C|>
];

viz[] := Module[{dof},
dof = {4, 5, 6};
BLDontDraw[{"torso"}];
BLRadius[0.09];
BLWidth[0.06];

<|
"axes" -> {1, 2},

"scale" -> r,

"poi" -> <|
"trunk" -> \[DoubleStruckB]["torso", dof, torso],
"left foot" -> \[DoubleStruckB]["left leg", dof, foot], "right foot" -> \[DoubleStruckB]["right leg", dof, foot]|>,

"lc" -> <|"right foot" -> LightGray|>
|>
];

CreateModel[] := Module[{com, c},
RBDNewModel[];

RBDLink["\[Theta]", Root, "m" -> 1, "S"-> "pz"];

RBDLink["torso", Root, "m" -> Mh, "S"-> "pln"];

com = {0, L, 0};
RBDLink["torso-1", "torso", "m" -> Mt, "S"-> "rz", "com" -> com];

com = {0, -r/2, 0};
c = {"left leg", "right leg"};
RBDLink[c, "torso", "m" -> m, "com" -> com, "S"-> "rz"];

RBDLink["torso-1", Merge];
RBDCreateModel["g" -> g];
];


(* ::Input::Initialization:: *)
CompassGaitWithTorsoP[cp_, opts:OptionsPattern[]] := CompassGaitWithTorsoP[BLbiped["m[0]"], cp, opts]["R"];

CompassGaitWithTorsoP[m_String, cp_, opts:OptionsPattern[]] := Module[{M, C},
M = BLP[m, cp, opts];
C = M["c"][[1, All, -(n\[Mu]+1);;-2]];
M["R"] = MapThread[Join, {M["R"], C}];
M
];


(* ::Input::Initialization:: *)
spring[x_, c_] := Module[{x1,x2,x3, K},
K = c[[nc-1]];
{x1,x2,x3} = x[[{5, 6, 4}]];
{0, 0, 0, -K (x1+x2-2 x3), K (x1-x3),K (x2-x3)}
]

u[x_, c_] :=  {0, 0, 0, 0, 1, -1} c[[nc-2]];


(* ::Input::Initialization:: *)
fixcons[] := Module[{C},
(* don't expand certain constraints *)
C = {_, _, ((\[DoubleStruckB]')|\[DoubleStruckB])[__], __};
C = Flatten@Position[RigidBodyDynamics`Private`con, C];
RigidBodyDynamics`Private`con[[C, -2]] = False;

(* update con fcns & data *)
RBDSpatialFunctions[];
]


(* ::Input::Initialization:: *)
CompassGaitWithTorso[n_:0] := Module[{A, C, X, J, l, r, draw, F, L, R},
CreateModel[];

ufun = u[##]-spring[##]&;

(* coordinate flip *)
A = BLA[];

(* feet constraints *)
F = {left, right};

(* create dynamic regimes *)
L = BLRegime["left", regopt["left"]];
R = BLRegime["right", regopt["right"]];
C = Join[L, R];

(* create jumps given state of biped at transition at t- (pre-impact) *)
L = BLxT["left", "ST" -> right, "SW" -> left, "A" -> A];
R = BLxT["right", "ST" -> left, "SW" -> right, "A" -> A];
X = Join[L, R];

(* create state-time-control space parameters *)
J = <|"A" -> A|>;
A = BLCreateBiped["Compass Gait with Torso", C, X, viz[], F, J];
C = Join[cm["left", A], cm["right", A]];
BLCreateContinuationParameters["right", C];

(* compile biped down to C code *)
BLCompileBiped[n]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
