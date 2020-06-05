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
BeginPackage["BipedalLocomotion`", {"GlobalVariables`", "RigidBodyDynamics`", "HybridDynamics`", "BipedalLocomotion`Model`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
Options[BLIndicatorFunction] = {Map -> {}(*BLSim*)};

BLIndicatorFunction::Map = "The Map option is deprecated and no longer used.";

BLIndicatorFunction[root_, t_, opts:OptionsPattern[]] := Module[{m, c, x, p, flow, ind}, 
m = BLbiped["m[0]"];
c = BLbiped["\[DoubleStruckC]", m, "eq"];
flow = OptionValue[Map];
If[flow =!= {}, Message[BLIndicatorFunction::Map];];
ind = BLbiped["p", m, "x"];
With[{c0 = c, f = flow, i = ind},
Module[{cT, dx},
cT = c0[##];
dx = root[cT(*, Map \[Rule] f*)][[2, i, i]];
Chop[Det[dx], 10^-8]
]&
]
];

Options[BLIndicatorFunctionPlot] = {Plot -> {}, BLIndicatorFunction -> {}};
BLIndicatorFunctionPlot[root_, t_, opts:OptionsPattern[]] := Module[{I},
I = BLIndicatorFunction[root, Max@t, OptionValue[BLIndicatorFunction]];
Plot[I[s], {s, Min@t, Max@t}, Evaluate@OptionValue[Plot], Epilog->{Red, Thick, InfiniteLine[{{0,0}, {1, 0}}]}]
];


(* ::Input::Initialization:: *)
BLIndicatorFunctionQ[R_:BLP, c_:Automatic] := Module[{m0, c0, i, A},
m0 = BLbiped["m[0]"];
c0 = Which[
c === Automatic, BLbiped["\[DoubleStruckC]", m0, "eq"][0.5], 
NumericQ@c, BLbiped["\[DoubleStruckC]", m0, "eq"][c], 
True, c];
i = BLbiped["p", m0, "x"];
A = R[c0][[2, i, i]];
{Chop[Det@A, 10^-6], TableForm[A, TableHeadings -> RBDGetDOF@BLGetValue@{i, i}]}
]


(* ::Input::Initialization:: *)
Options[BLFindBifurcation] = {FindRoot -> {}, BLIndicatorFunction -> {}, Method -> Root};

BLFindBifurcation[root_, t_, tmax_:Automatic, o:OptionsPattern[]] := BLFindBifurcation[OptionValue[Method], root, t, tmax, o]

BLFindBifurcation[None, root_, t_, tmax_:Automatic, OptionsPattern[]] := Module[{IF, T, s},
T = If[tmax === Automatic, 1.1 t, tmax];
With[{I = BLIndicatorFunction[root, T, OptionValue[BLIndicatorFunction]]}, IF[s_Real] := I[s]];
T = t;
{T, IF[T]}
]

BLFindBifurcation[Root, root_, t_, tmax_:Automatic, OptionsPattern[]] := Module[{IF, T, s},
T = If[tmax === Automatic, 1.1 t, tmax];
With[{I = BLIndicatorFunction[root, T, OptionValue[BLIndicatorFunction]]}, IF[s_Real] := I[s]];
T = s /. First@FindRoot[IF[s] == 0, {s, t}, Evaluate@OptionValue[FindRoot]];
{T, IF[T]}
]

BLFindBifurcation[Min, root_, t_, tmax_:Automatic, OptionsPattern[]] := Module[{IF, T, s},
T = If[tmax === Automatic, 1.1 t, tmax];
With[{I = BLIndicatorFunction[root, T, OptionValue[BLIndicatorFunction]]}, IF[s_Real] := I[s]];
T = s /. Last@FindMinimum[{IF[s], t <= s <= T}, {s, t}, Evaluate@OptionValue[FindRoot], StepMonitor:> Print[s]];

{T, IF[T]}
]

BLFindBifurcation[root_, {t0_, t1_, n_:Automatic}, tmax_:Automatic, OptionsPattern[]] := Module[{IF, T, TD, m},
T = Max[t0, t1];
T = If[tmax === Automatic, 1.1 T, tmax];
IF = BLIndicatorFunction[root, T, OptionValue[BLIndicatorFunction]];
T = {Min[t0, t1], Max[t0, t1]};
m = If[n === Automatic, 100., n];
{T, TD} = AllRoots[IF, T[[1]], T[[2]], All, N@m];
TD = ListPlot[TD, Joined->True, Epilog->{Red, Thick, InfiniteLine[{{0,0}, {1, 0}}], Black, PointSize[Large], Point[{#, 0}& /@ T]}];
{T, IF /@ T, TD}
]


(* ::Input::Initialization:: *)
End[]
EndPackage[]
