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
BeginPackage["BipedalLocomotion`Model`", {"GlobalVariables`", "Derivatives`", "RigidBodyDynamics`", "BipedalLocomotion`", "HybridDynamics`"}]

Begin["`Private`"]


(* ::Input::Initialization:: *)
BLSide[s_, f_:Automatic, i_:All] := Module[{F},
F = If[f === Automatic, {"left", "right"}, f];
If[StringContainsQ[s, "left", IgnoreCase->True], F, Reverse@F][[i]]
];


(* ::Input::Initialization:: *)
(* a = 2\[Pi] => \[Theta] \[Element] (-pi pi] *)
SetAttributes[BLAngle, Listable];
BLAngle[q_, a_:2\[Pi]] := Module[{x = Mod[q, a]}, If[x>\[Pi], x - a, x]];

BLSetAngles[r_:{"rx", "ry", "rz"}] := Module[{m, f, n},
angles = BLIndices["", r];

(* get all reduced space variables *)
m = BLbiped["m[0]"];

(* has BLCreateContinuationParametes been called? *)
angs = RBDGetValue[BLbiped["c", m, "x"], "n" -> True];

(* keep angles in reduced space *)
n = Range@Length@angs;
f = Head[angs[[#]]] === \[DoubleStruckQ] && StringContainsQ[angs[[#, 2]], r]&;
angs = Transpose@List@Select[n, f];
];

Options[BLState] = {"a" -> True};
BLState[x_, OptionsPattern[]] := If[OptionValue["a"],
(* assume reduced coordinates *)
MapAt[BLAngle, x, angs],
(* else full coordinates *)
MapAt[BLAngle, x, angles]
];


(* ::Input::Initialization:: *)
BLGetBipedBase[base_:Automatic] := Module[{i, b},
b = If[VectorQ[base], base[[1]], base];
If[b === Automatic,
b = KeyDrop[RBDGetLinkInfo["p"], "\[Theta]"];
b = First@Keys@Select[b, # === Root&];
If[VectorQ[base], b = Prepend[base[[2;;]], b]];
];
b
];


(* ::Input::Initialization:: *)
BLFeet[feet_, Automatic] := Module[{d},
d = BLValues[BLGetBipedBase[], "p"][[All, 2]];
d = d /. Thread[{"px", "py", "pz"}-> Range[mm+1, nm]];
BLFeet[feet, d]
];

BLFeet[feet_, 2] := BLFeet[feet, Range[mm+1, nm-1]];
BLFeet[feet_, 3] := BLFeet[feet, Range[mm+1, nm]];

BLFeet[feet_, dof_] := Module[{f, b, d},
Which[
feet === {}, Return@<||>,
StringQ[feet[[1]]], f = {feet};, 
True, f = feet;
];

b = Table[\[DoubleStruckB][i[[1]], j, i[[2]]], {i, f}, {j, dof}];
b = Table[i -> b[[i]], {i, Length@b}];
<|Prepend[b, "f" -> f]|>
];

BLGetFootFalls[\[CurlyPhi]_] := Module[{xpre, xpost, x, c, f, p, a, b},
{c, xpre, xpost} = Values@\[CurlyPhi][[{"c", "x-", "x+"}, 2;;]];
If[Length@c <= 1 || Length@xpre <= 1 || Length@xpost <= 1, Return@{}];

x = MapThread[List, {xpost, xpre[[2;;]]}];
f = BLbiped["feet"];

(* p = {{x0 = {6D foot location, 6D foot location}, xf}, {x0, xf}, ..., } *)
p = Table[
RBDSpatialPosition[f[[k, 2]], f[[k, 1]], "x" -> x[[i, j]], "\[Lambda]" -> c[[i]]],
{i, Length@c}, {j, Length@x[[i]]}, {k, Length@f}
];

(* order p s.t. p\[LeftDoubleBracket]i, k\[RightDoubleBracket] = {stance foot, swing foot} *)
f = First@Ordering[(Norm /@ Join[#1-#2, Reverse@#1 - #2])]&;
Table[
a = p[[i, 1]];
b = p[[i, 2]];

Switch[f[a, b],
1, {a, b},
2, {Reverse@a, Reverse@b},
3, {Reverse@a, b},
4, {a, Reverse@b}
],
{i, Length@p}
]
];


(* ::Input::Initialization:: *)
Options[BLLinks] = {"b" :> RBDLinks[], "i" -> False, Not -> False};

BLLinks[form_, opts:OptionsPattern[]] := Module[{b, i, f},
b = OptionValue["b"];
f = If[OptionValue[Not], StringFreeQ, StringContainsQ];
i = Select[Range@Length@b, f[b[[#, 1]], form]&];
(* return indices or sublist? *)
If[OptionValue["i"], i, b[[i]]]
];

Options[BLValues] = {"n" -> \[DoubleStruckQ], BLLinks -> {}, Not -> False};
BLValues[fb_, fd_:"", opts:OptionsPattern[]] := Module[{q, n, b, f}, 
(* get links that match form fb *)
b = BLLinks[fb, OptionValue[BLLinks]];
(* get string name for dof *)
q = Flatten[RBDGetDOF[\[DoubleStruckQ][#[[1]], Values]]& /@ b];
(* get dofs that match form fd *)
f = If[OptionValue[Not], StringFreeQ, StringContainsQ];
q = Cases[q, \[DoubleStruckQ][_, n_] /; f[n, fd]];
(* change head *)
n = OptionValue["n"];
If[VectorQ[n], Flatten[q /. \[DoubleStruckQ] -> #& /@ n], q /. \[DoubleStruckQ] -> n]
];

BLIndices[fb_, fd_:"", opts:OptionsPattern[]] := RBDGetIndex@BLValues[fb, fd, opts]


(* ::Input::Initialization:: *)
BLJacobian[p_] := Module[{i, M, m, \[Sigma]T, \[Sigma]0, x, c, \[Sigma], S, dSdT, dSdc, dTdc, f, A},
M = BLSim[p];

m = M[["m", 1]];
i = BLbiped["c", m, "x"];
A = Lookup[BLbiped, "A", BLA[]];
A = A[[i, i]];

m = M[["m", -1]];
c = devec[M[["c", -1]], nc];

(* t = 0 *)
x = devec[M[["x+", 2]], nx];
\[Sigma]0 = devec[BLbiped["\[Sigma]", m][x, c], mm][[All, 3]];

(* t = T *)
x = devec[M[["x-", -1]], nx];
\[Sigma]T = devec[BLbiped["\[Sigma]", m][x, c], mm][[All, 3]];

\[Sigma] = \[Sigma]T-\[Sigma]0;

(* dTdc *)
S = Sin[\[Sigma][[1]]];
dSdT = Cos[\[Sigma][[1]]] \[Sigma][[2, -1]];
dSdc = Cos[\[Sigma][[1]]] \[Sigma][[2]];
dTdc = -dSdc/dSdT;

(* get state-based derivative *)
f = x[[2, All, -1]];
f= KroneckerProduct[f, dTdc];

{A.(x[[2, i]] + f[[i]]), A.x[[2, i]]}
];

JFD[c_, tol_:10^-5] := Module[{m, i, f, Jtb, Jeb, A},
m = BLbiped["m[0]"];
i = BLbiped["c", m, "x"];
f = blstate[#][["x-", -1, i]]&;
Jeb = FiniteDifferenceJacobian[f, c, N@tol]\[Transpose];

f = BLSim[#][["x-", -1, i]]&;
Jtb = FiniteDifferenceJacobian[f, c, N@tol]\[Transpose];

A = Lookup[BLbiped, "A", BLA[]];
{A.Jeb, A.Jtb}
];

BLEigenvalues[man_, max_:True] := Module[{m, i, j, J, eigs, c},
m = BLbiped["m[0]"];
j = BLbiped["p", m, "x"];

(* fancier select would ensure dSdT \[NotEqual] 0 *)
c = Select[man[[All,1]], !PossibleZeroQ[Norm[#[[j]]]]&];

J = BLJacobian[#][[All, All, j]]& /@ c;
eigs = Map[Eigenvalues, J, {2}];

If[max, Map[Max@Abs@#&, eigs, {2}], eigs]
]


(* ::Input::Initialization:: *)
Options[BLWalk] = {BLAnimateBiped -> {}, "e" -> False, "T" -> -1};
BLWalk::k = "`` `` does not exist.  Valid ones are: ``.";

BLWalk[A_Association, k_?VectorQ, n_:1, opts:OptionsPattern[]] := If[KeyExistsQ[A, k], BLWalk[A[k][[1]], n, opts], Message[BLWalk::k, "Key", k, Keys@A]];

BLWalk[A_Association, k_Integer, n_:1, opts:OptionsPattern[]] := If[Length@A > k, BLWalk[A[[k, 1]], n, opts], Message[BLWalk::k, "Index", k, "1 <= k <= " <> ToString@Length@A]];

BLWalk[c_, n_:1, opts:OptionsPattern[]] := Module[{o, e, T},
o = OptionValue[BLAnimateBiped];
e = OptionValue["e"];
T = OptionValue["T"];
If[e, 
(* state-based *)
e = state[c, n];
T = c[[T]]{0, n};,
(* else *)
(* time-based *)
e = c;
T = c[[T]]Range[0, n];
];

BLAnimateBiped[e, o, BLSim -> {"T" -> T}]
];

BL\[Sigma][c_?VectorQ] :=BL\[Sigma]@@BLmxcp[BLbiped["m[0]"], c];

BL\[Sigma][m_, x_?VectorQ, c_?VectorQ] :=BL\[Sigma][m, devec[x, nx], devec[c, nc]];

BL\[Sigma][m_, x_, c_] :=devec[BLbiped["\[Sigma]", m][x, c], mm];

blevent[m_, x_?VectorQ, c_?VectorQ] := Module[{X, C, \[Sigma], n},
X = devec[x, nx];
C = devec[c, nc];

(*n = First@Complement[Range[mm+1, nm],  ax]-mm;*)
n = mm;

(*\[Sigma] = BL\[Sigma]["left", X, C]\[LeftDoubleBracket]1, n\[RightDoubleBracket]-BL\[Sigma]["left", C\[LeftDoubleBracket]All, 1;;nx\[RightDoubleBracket], C]\[LeftDoubleBracket]1, n\[RightDoubleBracket];*)

\[Sigma] = (x[[4]]+0.5x[[5]])-(c[[4]]+0.5c[[5]]);

Sin[\[Sigma]]
];

blstate[p_, n_Integer:1] := Module[{Tc, m, x, c, esw, r},
Tc = p[[-1]];
m = BLbiped["m[0]"];
{m, x, c} = BLmxcp[m, p];

esw = {
WhenEvent[\[DoubleStruckT]-0==0,{\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],"RemoveEvent"},{"Priority"->1}],

WhenEvent[blevent[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]] > 0,{Print[\[DoubleStruckT], " ", \[DoubleStruckM][\[DoubleStruckT]], " ", blevent[\[DoubleStruckM][\[DoubleStruckT]], \[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]]];\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0]},{"Priority"->2}]
};

\[CurlyPhi][m, x, c, {0, n Tc}, "e" -> esw]
];


(* ::Input::Initialization:: *)
\[Sigma][q_] :=q[[4]]+0.5q[[5]];

be[x_?VectorQ, c_?VectorQ] := Sin[\[Sigma][x]-\[Sigma][c]];

(*be[m_, x_?VectorQ, c_?VectorQ] := Module[{X, C},
X = devec[x, nx];
C = devec[c, nc];
Sin[BL\[Sigma][m, X, C]-BL\[Sigma][m, C\[LeftDoubleBracket]All, 1;;nx\[RightDoubleBracket], C]]
];*)

(* for simulation *)
state[p_, n_Integer:1] := Module[{Tc, m, x, c, DTsw, Tsw, esw, r},
Tc = p[[-1]];
m = BLbiped["m[0]"];
{m, x, c} = BLmxcp[m, p];

esw = {
WhenEvent[\[DoubleStruckT]-0==0,{\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],"RemoveEvent"},{"Priority"->1}],

WhenEvent[be[\[DoubleStruckX][\[DoubleStruckT]], \[DoubleStruckC][\[DoubleStruckT]]] > 0,{\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`TF[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0],\[DoubleStruckM][\[DoubleStruckT]]->HybridDynamics`Private`m[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`h[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckC][\[DoubleStruckT]]->HybridDynamics`Private`d[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]]],\[DoubleStruckX][\[DoubleStruckT]]->HybridDynamics`Private`T0[\[DoubleStruckM][\[DoubleStruckT]],\[DoubleStruckX][\[DoubleStruckT]],\[DoubleStruckC][\[DoubleStruckT]],0]},{"Priority"->2}]
};

\[CurlyPhi][m, x, c, {0, n Tc}, "e" -> esw]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]