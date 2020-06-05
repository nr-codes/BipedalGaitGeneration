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
BeginPackage["BipedalLocomotion`FiveLink3D`", {"GlobalVariables`", "RigidBodyDynamics`", "BipedalLocomotion`", "BipedalLocomotion`Model`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
VHC[1] := Module[{},
ucon[s_] := DiagonalMatrix@{1, 1, \[DoubleStruckC][-2], \[DoubleStruckC][-2], 1, 1};

vcon[s_] := <|-1 -> {\[DoubleStruckQ]["left thigh", "rx"], \[DoubleStruckQ]["right thigh", "rx"]}, 3-> {\[DoubleStruckQ]["left thigh", "ry"], \[DoubleStruckQ]["right thigh", "ry"], \[DoubleStruckQ]["left foot", "ry"], \[DoubleStruckQ]["right foot", "ry"]}|>;

qrm[s_] := Module[{t, w},
(* pre-impact stance/swing x[0-]/c- *)
{t, w} = stsw[s];
(* remove following configurations *)
{{"thigh", "rx"}}
];

vrm[s_] := Module[{t, w},
(* pre-impact stance/swing x[0-]/c- *)
{t, w} = stsw[s];
(* remove following velocities *)
{{"thigh", "rx"}}
];

FiveLink3DP[m_String, cp_, opts:OptionsPattern[]] := Module[{M, R, C, i, j, n},
M = BLP[m, cp, opts];
C = M["c"][[1, All, -(n\[Mu]+1);;-2]];
R = M["R"];

n = Length[BLbiped["p", m, "x"]]/2;

i = {11, 12};
i = Join[i, i + nq];
j = {5, 6};
j = Join[j, j + n];

R[[All, j]] = M["c"][[1, All, i]];

M["R"] = MapThread[Join, {R, C}];
M
];
];


(* ::Input::Initialization:: *)
VHC[2] := Module[{},
(* continuation matrix *)
ucon[s_] := DiagonalMatrix@Join[{1, 1}, BLSide[s, {{1, \[DoubleStruckC][-2]}, {\[DoubleStruckC][-2], 1}}, 1], {1, 1}];

vcon[s_] := Module[{t, w},
(* post-impact stance/swing x[0+]/c+ *)
{t, w} = stsw[s];
(* virtual constraints *)
<|3 -> {{"thigh"| "foot"}}|>
];

qrm[s_] := Module[{t, w},
(* pre-impact stance/swing x[0-]/c- *)
{t, w} = stsw[s];
(* remove following configurations *)
{{"thigh", "rx"}}
];

vrm[s_] := Module[{t, w},
(* pre-impact stance/swing x[0-]/c- *)
{t, w} = stsw[s];
(* remove following velocities *)
{{"thigh", "rx"}}
];

FiveLink3DP[m_String, cp_, opts:OptionsPattern[]] := Module[{i, j, n, M, C},
M = BLP[m, cp, opts];
n = Length@BLbiped["c", m, "x"]/2;

(* left thigh = 0 @ t = T- => right thigh = 0 @ t = 0- *)
i = {3};
i = Join[i, i + n];
j = {8};
j = Join[j, j+nq];
(* next pre-impact state *)
M[["R", All, i]] = M[["x-", -1, All, j]];

(* left foot = 0 @ t = 0+ => left foot q = 0 @ t = 0- *)
i = {5};
i = Join[i, i + n];
j = {11};
j = Join[j, j+nq];
(* first post-impact state *)
M[["R", All, i]] = M[["x+", 2, All, j]];

(* right foot = 0 @ t = 0- *)
i = {6};
i = Join[i, i + n];
j = {12};
j = Join[j, j+nq];
(* initial pre-impact state *)
M[["R", All, i]] = M[["x-", 1, All, j]];

C = M["c"][[1, All, -(n\[Mu]+1);;-2]];

M["R"] = MapThread[Join, {M["R"], C}];

M
];
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
