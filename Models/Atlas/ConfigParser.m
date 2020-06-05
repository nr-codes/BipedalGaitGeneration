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
BeginPackage["BipedalLocomotion`Atlas`", {"GlobalVariables`", "RigidBodyDynamics`", "BipedalLocomotion`", "BipedalLocomotion`Model`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
model = Import["Atlas/atlas.cfg"];
model = If[Length@# == 0, {""}, #]& /@ model;

footDAE = Import["./Atlas/Atlas/meshes/l_foot.dae", "Graphics3D"];
coordsDAE = Import["./Atlas/Atlas/meshes/l_foot.dae", "VertexData"];


(* ::Input::Initialization:: *)
GetRecord[n_] := Module[{struct, start, stop, N, pos, joint, r},
N = Length@model;
struct = StringSplit[n, "."];
start = 1;
Do[
While[start <= N && !StringMatchQ[s, StringTrim[model[[start, 1]]]], start++],
{s, "struct " <> #& /@  struct}
];

stop = start;
If[stop < N,
While[stop <= N && StringLength[StringTrim[model[[stop, 1]]]] > 0, stop++];
];

{start, stop}
];

SetAttributes[GetValue, Listable];
GetValue[m_] := Module[{vals},
vals = StringSplit[m];
If[Length@vals == 1,
Internal`StringToDouble[First@vals],
Internal`StringToDouble /@ vals
]
];

GetLinkNames[] := Module[{l, rc},
rc = {};
Do[
l = StringSplit[model[[i, 1]]];
If[Length@l > 0 && StringMatchQ["link_names", l[[1]]], 
rc = l[[3;;]];
Break[]
];,
{i, Length@model}
];

rc
];

SetAttributes[ParseLink, Listable];
ParseLink[rec_] := Module[{n, m, start, stop, pat},
{start, stop} = GetRecord[rec];
If[start == stop, Return[$Failed]];

n = StringSplit[model[[start,1]]][[2]];
m = StringSplit[Flatten@model[[start+1;;stop-1]], "=", 2];
m = StringTrim /@ m;

pat = Join[Thread[m[[All, 1]]-> m[[All,2]]], {"parent_link"-> "root","parent_kin_dof"-> "float.base"}];

m = {"index","parent_link","parent_kin_dof","mass","0","0","0", "com_x","com_y","com_z", "moi_xx","moi_xy","moi_xz","moi_xy","moi_yy","moi_yz","moi_xz", "moi_yz","moi_zz"} /. pat;

m[[1]] = n-> Floor[GetValue[m[[1]]]] + 1;
m[[4;;]] = GetValue[m[[4;;]]];
m
];

SetAttributes[ParseJoint, Listable];
ParseJoint["float.base"] = {"float.base", "fb", z6, z3};
ParseJoint[rec_] := Module[{m, j, pat, start, stop, \[Theta], axis},
{start, stop} =  GetRecord[rec];
If[start == stop, Return[$Failed]];

j = "r" <> StringTake[rec, -1];
m = StringSplit[Flatten@model[[start+1;;stop-1]], "=", 2];
m = StringTrim /@ m;

pat = Thread[m[[All, 1]]-> m[[All,2]]];

m = {rec, j, "offset", "axis"} /. pat;
m[[3]] = "0 0 0 " <> m[[3]];

m[[3;;4]] = GetValue[m[[3;;4]]];

m
]


(* ::Input::Initialization:: *)
AxisAngleToQuaternion[axis_, \[Theta]_] := Module[{a, s, c},
a = \[Theta]/2;
s = Sin[a];
c = Cos[a];
Append[s Normalize@axis, c]
];

AxisAngleToRotation[axis_, \[Theta]_] := Module[{x, y, z, w},
{x, y, z, w} = AxisAngleToQuaternion[axis, \[Theta]];
{
{1-2y^2-2z^2, 2x y-2z w, 2x z+2y w},
{2x y+2z w, 1-2x^2-2z^2, 2y z-2x w},
{2x z-2y w, 2y z+2x w, 1-2x^2-2y^2}
}
];

Eaxis\[Theta][axis_, \[Theta]_] := Module[{E},
E = RBDExpandExpression@AxisAngleToRotation[axis, \[Theta]]\[Transpose];
RigidBodyDynamics`Private`Mat6[E, Z3, Z3, E]
];

CreateModelData[] := Module[{parent, links, joints, p(*, axis, \[Theta]*), frames, inertia, S},
links = GetLinkNames[];

links = ParseLink[links];
joints = ParseJoint[links[[All, 3]]];
parent = links[[All, 2]] /. Append[links[[All, 1]], "root"-> 0];
frames = joints[[All, 3]];
inertia = links[[All, 4;;]];

(* .cfg file has two frames a joint frame and axis frame *)
(* the axis frame describes the dof using axis-angle notation *)
(* so add to joint library *)
RBDJoint["float.base", RBDJoint["fb"]];
With[{axis = #[[3]]}, RBDJoint[#[[1]], Join[axis, z3]&, Eaxis\[Theta][axis, #]&]] & /@ joints[[2;;-1, {1,2,-1}]];

(* replace #s with names *)
parent = If[# > 0, joints[[#, 1]], Root]& /@ parent;

(* joint type \[Rule] joint name *)
S = joints[[All, 1]];

(* return robot model *)
Flatten /@ ({joints[[All, 1]], parent, S, frames, inertia}\[Transpose])
];


(* ::Input::Initialization:: *)
PutArmsDown[] := Module[{n, sides, arms, R, total, pt, ang, p, i, ind, L},
sides = {"l.arm.", "r.arm."};
arms = {"ely", "elx", "wry", "wrx"};
L = atlas[[All, RBDindex["n"]]];

Do[
total = 0;
Do[
n = s <> a;
(* find link *)
i = Position[L, n][[1,1]];
(* find parent *)
p = Position[L, atlas[[i, RBDindex["p"]]]][[1,1]];
ind = RBDindex["f[xyz]"];

(* get link frame *)
pt = atlas[[i, ind]];
R = RigidBodyDynamics`Private`rotX[total];
pt = RigidBodyDynamics`Private`MovePoint[R, pt];

ang = ArcCos[Dot[pt, {0,0,-1}]/Norm[pt]];
ang = -Sign[pt[[2]]] ang;

(* add RX rotation *)
ind = RBDindex["f"][[1]];
atlas[[p, ind]] = ang;

(* update absolute angle *)
total = total + ang;,
{a, arms}
];,
{s, sides}
];
];

SetAttributes[POI, Listable];
POI[n_] := Module[{i, c, poi},
i = Position[atlas[[All, RBDindex["n"]]], n];
If[Length@i == 0, Return[]];
i = i[[1, 1]];
(* get the child link *)
c = Position[atlas[[All, RBDindex["p"]]], n];
If[Length@c == 0, 
(* get point @ com *)
poi = atlas[[i, RBDindex["c"]]];,
(* get point @ end of link *)
c = c[[1, 1]];
poi = atlas[[c, RBDindex["f"]]];
];

{n, poi[[4;;6]]}
];


(* ::Input::Initialization:: *)
FootPOI[] := Module[{toe, heel, wt, wh, h},
{toe, heel} = GetFootData[][[1;;2]];

Join@@Table[
{i, #}& /@ {
{toe[[1]], -toe[[2]]/2, toe[[3]]}, 
{toe[[1]], toe[[2]]/2, toe[[3]]}, 
{heel[[1]], -heel[[2]]/2, heel[[3]]},
{heel[[1]], heel[[2]]/2, heel[[3]]}},
{i, {"l.leg.akx", "r.leg.akx"}}
]
]


(* ::Input::Initialization:: *)
GetFootData[] := Module[{box, h, toe, heel},
(* get bottom four corners *)
box = MinimalBy[coordsDAE, #[[3]]&, 32];
box = Join[MinimalBy[box, #[[1]]&, 6], MaximalBy[box, #[[1]]&, 6]];
box = DeleteDuplicates[box, Norm[#1-#2]<= 10^-6&];
box = Join[MinimalBy[box, #[[2]]&, 2], MaximalBy[box, #[[2]]&, 2]];

(* sort heel coords then toe coords *)
box = SortBy[box, First];
h = Mean@box[[All, 3]];

(* heel = (heel, wh, h) *)
heel = {Mean@box[[1;;2, 1]], Total@Abs@box[[1;;2, 2]], h};

(* toe *)
toe = {Mean@box[[3;;4, 1]], Total@Abs@box[[3;;4, 2]], h};

(* x left to right, y into screen, z up *)
{toe, heel, Show[{footDAE, Graphics3D[{PointSize@0.01, Red, Point[z3]}], Graphics3D[{PointSize@0.01, Blue, Point[box[[1;;2]]], Green, Point[box[[3;;4]]]}]}]}
]


(* ::Input::Initialization:: *)
End[]
EndPackage[]
