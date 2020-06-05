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
BeginPackage["BipedalLocomotion`", "GlobalVariables`"]
Begin["`Private`"]

(* boundary condition types *)
BC = {"p0", "v0", "vT", "pT"}; 


(* ::Input::Initialization:: *)
Bezier[s_, p_, dom_:{0, 1}] := Module[{M, f, a, b},
{a, b} = dom; (* scale to interval s \[Element] [a, b] *) 
(* computes bi(s) & bi'(s) given a set of p coefficients *)
M = Length@p - 1;
f = Sum[p[[k+1]] Binomial[M, k] (#-a)^k (b-#)^(M-k), {k, 0, M}]&;
Which[
(NumericQ@s && NumericQ@a && s == a) || s === a,
{p[[1]] (b - a)^M, M (p[[2]]-p[[1]]) (b - a)^(M-1)},
(NumericQ@s && NumericQ@b && s == b) ||  s === b,
{p[[M+1]] (b - a)^M, M(p[[M+1]]-p[[M]]) (b - a)^(M-1)},
True,
{f[s], f'[s]}
]
];


(* ::Input::Initialization:: *)
SetAttributes[{BoundaryCoefficients, FreeCoefficients}, Listable];

(* valid combinations for options are: M = 0 \[Rule] (* either position *), M = 1 \[Rule] (* any 2 except 2 velocities *), M = 2 \[Rule] (* any 3 *)*)
Options[BoundaryCoefficients] = 
{"-1" -> {}, "0" -> BC[[{1}]], "1" -> BC[[{1, -1}]], "2" -> BC[[{1, 2, -1}]], "3" -> BC};

BoundaryCoefficients[M_, OptionsPattern[]] := Module[{\[Alpha], n, b},
(* get indices of boundary conditions *)
If[M < 0, Return@{{}, {}, {}, {}}];
n = (M+1);
\[Alpha] = Range[#, n, M+1]& /@ {1, M+1};
\[Alpha] = Join[\[Alpha][[1]], \[Alpha][[1]]+1, \[Alpha][[2]]-1, \[Alpha][[2]]];

(* get boundary conditions *)
n = ToString@Min[M, 3];
b = BC; (* boundary conditions *)
b = If[StringMatchQ[#, OptionValue[n]], 1, {}]& /@ b;
(* return index or empty set *)
\[Alpha] b
];

FreeCoefficients[M_, opts:OptionsPattern[]] := Module[{\[Alpha]},
\[Alpha] = BoundaryCoefficients[M, opts];
Complement[Range[M+1], \[Alpha]]
];


(* ::Input::Initialization:: *)
ParameterOffset[M_] := FoldList[#1 + #2+1&, 0, M]; (* returns offsets and length (last element) *)

Coefficients[M_] := Module[{a},
a = ParameterOffset[M];
(* {start index, end index} *)
Range@@ {a[[1;;-2]]+1, a[[2;;-1]]}
];

NumberOfCoefficients[M_] := Length@Flatten@Coefficients[M];


(* ::Input::Initialization:: *)
PolynomialCoeffcients[M_, opts:OptionsPattern[]] := Module[{b, p, i, j, n, I, P, N},
(* label boundary coefficients based on boundary type *)
n = Length@M;
b = BC;
P = Coefficients[M];
I = BoundaryCoefficients[M, opts];
N = Range@n;
P = Association@Table[
(* extract coefficients of the k^th boundary type *)
i = Flatten /@ I[[All, {k}]];
p = Flatten@MapThread[Part, {P, i}];
(* get polynomial function they appear in *)
j = Select[N, Length@i[[#]] > 0&];
If[StringContainsQ[b[[k]], "v"], j = j + n;];

b[[k]] -> {p, j},
{k, Length@BC}
];

(* combine 0 and f labels *)
b = {{"\[Eta]0", "p0", "v0"}, {"\[Eta]T", "pT", "vT"}};
Do[
p = Transpose@Values@P[[k[[2;;3]]]];
p = Sort /@ Join@@@p;
AssociateTo[P, k[[1]] -> p];,
{k, b}
];

(* add free indices *)
p = FreeCoefficients[M, opts];
If[M =!= {}, p = p + ParameterOffset[M[[1;;-2]]];];
p = Sort /@ {Flatten@p, Select[N, Length@p[[#]]>0&]};
AssociateTo[P, "\[Alpha]" -> p];

(* return association w/ key \[Rule] {{coeff. indices}, {corresp. fcn indices}} *)
P 
];


(* ::Input::Initialization:: *)
PolynomialFunction[M_, f_:Bezier] := Module[{\[Alpha], s, b},
b = Map[\[Alpha], Coefficients[M], {2}];
b = Flatten@Transpose@Simplify[f[s, #]& /@ b];
Evaluate@b& /. {s -> #1, \[Alpha][i_] :> #2[[i]]}
];

Options[PolynomialPlot] = {"f" -> Bezier, "d" -> {0, 1}, Plot -> {}, "i" -> All};

PolynomialPlot[p_, M_, opts:OptionsPattern[]] := Module[{f, d, i, b, s},
i = OptionValue["i"];
f = OptionValue["f"];
d = OptionValue["d"];
b = PolynomialFunction[M, f];
b = b[s, p][[i]];
Plot[b, {s, d[[1]], d[[2]]}, Evaluate@OptionValue[Plot]]
];


(* ::Input::Initialization:: *)
Options[PolynomialTrajectory] = {"f" -> Bezier, "c" -> 1, "CI" -> Sequence[]};

PolynomialTrajectory[M_, so\[Theta]_, opts:OptionsPattern[]] := Module[{f, b0, bT, \[Eta]d, n, p, i, j, I, m},
(* generate spline equations at end points of pre-impact trajectory *)
(* assumes linear relationship between hd and coefficients *)
f = OptionValue["f"];

n = Length@M;
p =PolynomialCoeffcients[M, OptionValue["CI"]];
\[Eta]d =PolynomialFunction[M, f];

(* offset *)
m = OptionValue["c"];

(* use c values starting from offset *)
I = Array[\[DoubleStruckC], Max[0, p[[All, 1]]], m];

(* scale velocities *)
{i, j} = p["\[Eta]0"];
b0 = \[Eta]d[0, I];
b0[[n+1;;2n]] = b0[[n+1;;2n]] so\[Theta][[2]];
b0 = D[b0[[j]], {I[[i]]}];

{i, j} = p["\[Eta]T"];
bT = \[Eta]d[1, I];
bT[[n+1;;2n]] = bT[[n+1;;2n]] so\[Theta][[2]];
bT = D[bT[[j]], {I[[i]]}];

\[Eta]d = \[Eta]d[so\[Theta][[1]], I];
\[Eta]d[[n+1;;2n]] = \[Eta]d[[n+1;;2n]]so\[Theta][[2]];

(* shift c indices *)
p[[{"\[Eta]0", "\[Eta]T", "\[Alpha]"}, 1]] = Values@p[[{"\[Eta]0", "\[Eta]T", "\[Alpha]"}, 1]] + m - 1;

p = p[[{"\[Eta]0", "\[Eta]T", "\[Alpha]"}]];
p["c"] = I;
p["\[Eta]d"] = \[Eta]d;
p["B0"] = b0;
p["BT"] = bT;

Simplify/@p
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
