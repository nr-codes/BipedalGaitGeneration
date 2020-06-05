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
Options[BLGetSwitchingTimes] = {"m" -> Automatic, "DT" -> Automatic};
BLGetSwitchingTimes[c_, OptionsPattern[]] := Module[{m, c0, DT, n},
(* get mode *)
m = OptionValue["m"];
If[m === Automatic, m = BLbiped["m[0]"];];
(* get indices of switching times *)
DT = OptionValue["DT"];
If[DT === Automatic, DT = BLbiped["t", m];];
(* flatten c for linear indexing; argument could be devec[c] *)
c0 = Flatten@c;
(* how long is parameter vector? *)
(* assume c = vec[{p, dp, ...}] is not an option *)
n = Min[Length@If[VectorQ[c], c, c[[1]]], nc];
(* get switching times, which are mapped at end of parameter vector *)
If[# == 0, 0, c0[[n-Abs[#]+1]]]& /@ DT
];


(* ::Input::Initialization:: *)
BLSwitchingTimes::indices = "Switching time indices have to be -'ve or zero.";
BLSwitchingTimes[n_Integer] := BLSwitchingTimes[Range[-n, -1]];
BLSwitchingTimes[T_] := Module[{},
If[Or@@Positive[T], Message[BLSwitchingTimes::indices]];
Select[T, Negative]
];

BLControlDesignParameters[n_, T_:0] := Module[{m},
If[IntegerQ[n],
m = If[T === {}, 0, Min@T];
Range[m-n, m-1],
(* else *)
n
]
];

BLPolynomialCoefficients[\[Alpha]_] := \[Alpha];

BLRemoveStates[base_, q_, v_] := Module[{a, f, b, b0, b1, b2, b3},
a = RBDGetValue[1, nx, "n" -> True];
b0 = BLValues["\[Theta]", "", "n" -> {\[DoubleStruckQ], \[DoubleStruckV]}];

b = (VectorQ[base] && base[[1]] === Automatic) || (base === Automatic);
b = If[b, BLGetBipedBase[base], base];
{b1, b2} = If[VectorQ[b], b, {b, "p"}];
b1 = If[b === None, {}, BLValues[b1, b2, "n" -> {\[DoubleStruckQ], \[DoubleStruckV]}]];

f = Flatten[BLValues[Sequence@@#]&/@ #]&;
b2 = Which[b === None, {}, ListQ[q], f[q], True, f[{{q, ""}}]];
f = Flatten[BLValues[Sequence@@#, "n" -> \[DoubleStruckV]]&/@ #]&;
b3 = Which[b === None, {}, ListQ[v], f[v], True, f[{{v, ""}}]];

RBDGetIndex@DeleteCases[a, Alternatives@@Join[b0, b1, b2, b3]]
];

BLTimeBasedceq[T_, a_] := Module[{t, ceq},
ceq = ConstantArray[0, nc];
ceq[[RBDGetIndex[\[DoubleStruckV]["\[Theta]", 1]]]] = 1;
(*ceq\[LeftDoubleBracket]T\[RightDoubleBracket] = Slot[1] Range@Length@T;*)
ceq[[T]] = Slot /@ Range@Length@T;
Evaluate@ceq[[a]]&
];

Options[BLContinuationParameters] = {"base" -> Automatic, "q" -> {}, "v" -> {}, "\[Alpha]" -> {}, "\[Mu]" -> {}, "T" -> {-1}, "c[p]" -> (#&), "c[T]" -> (#&), "c[eq]" -> BLTimeBasedceq, Association -> <||>};

BLContinuationParameters[OptionsPattern[]] := Module[{base, q, v, \[Alpha], \[Mu], T, x, a, t, u, i, p, cT, ceq},
base = BLGetBipedBase[OptionValue["base"]];
q = OptionValue["q"];
v = OptionValue["v"];
\[Alpha] = OptionValue["\[Alpha]"];
\[Mu] = OptionValue["\[Mu]"];
T = OptionValue["T"];

x = BLRemoveStates[base, q, v];
a = BLPolynomialCoefficients[\[Alpha]];
t = BLSwitchingTimes[T];
u = BLControlDesignParameters[\[Mu], t];

i = Join[x, a , u,t];
ceq = OptionValue["c[eq]"][t, i] ;

p = ConstantArray[0, nc];
p[[i]] = Array[\[DoubleStruckC], Length@i];
p[[nq+1]] = 1;
p = OptionValue["c[p]"]@p;

cT = OptionValue["c[T]"]@Join[Array[\[DoubleStruckX], nx], Array[\[DoubleStruckC], nc-nx, nx+1]];

q = "c" -> Association["x" -> x, "\[Alpha]" -> a, "\[Mu]" -> u, "T" -> t];
v = "\[DoubleStruckC]" -> Association["p" -> p, "T" -> cT, "eq" -> ceq];

(* get mapping of variables in p-(stc-)space *)
i = {{"x", "\[Alpha]", "\[Mu]", "T"}, Length /@ {x, a , u,t}}\[Transpose];
i = Select[i, #[[2]] > 0&];
\[Alpha] = Rest@FoldList[Range[#1[[-1]]+1, #1[[-1]]+#2]&, {0}, i[[All, 2]]];
(* add zero length variables back into p-(stc-)space *)
i = Join[i[[All, 1]], Complement[{"x", "\[Alpha]", "\[Mu]", "T"}, i[[All, 1]]]];
\[Alpha] = PadRight[\[Alpha], Length@i, {{}}];
\[Alpha] = "p" -> AssociationThread[i -> \[Alpha]];

Association[q, v, \[Alpha], OptionValue[Association]]
];

SetAttributes[BLSummary, Listable];
BLSummary::name = "`1` is not a valid mode.  Valid modes are `2`.";

BLSummary[] := BLSummary[Keys@BLbiped["m"]];

BLSummary[name_] := Module[{a, p, m, v, b},
If[MissingQ[BLbiped["BLSummary", name]], 
Return@Message[BLSummary::name, name, Keys@BLbiped["BLSummary"]]
];

(* get actuated links during regime (most likely post-impact) *)
v = Lookup[BLbiped["BLSummary", name], "V", {}];
m = Lookup[BLbiped["BLSummary", name], "B", Automatic];
p = BLConstraints[{}, v, {}, m];

m = RBDGetIndex@p["B"]-nq;
a = ConstantArray["u", nq];
b = ConstantArray[0, nq];
Do[a[[m[[i]]]] = p[["M", i]]; b[[m[[i]]]] = i;, {i, Length@m}];

(* get pre-impact dependent variables *)
p = BLbiped["c", name, "x"];
v = ConstantArray["d", nx];
v[[p]] = "i";

(* get pre-impact state *)
p = Array[\[DoubleStruckC], Total[Length/@BLbiped["c", name]]];
p = Quiet@Flatten@BLbiped["\[DoubleStruckC]", name, "p"][{p, {}, {}}];
p = {p[[1;;nq]], p[[nq+1;;nx]]};
v = {v[[1;;nq]], v[[nq+1;;nx]]};

p = Join[{RBDGetValue[1, nq, "n" -> True]}, v, p, {a, b}];

(* q-/v- are variables in previous mode that affect name regime *)
v = {Range@nq, {"q " <> name, "q-/i", "v-/i", "q-", "v-", "B+", "B"}};
TableForm[Transpose@p, TableHeadings->v]
];


(* ::Input::Initialization:: *)
BLA[ind1_:{}, ind0_:{}, r_:{"rx", "ry", "rz"}] := Module[{A, k, f, I},
(* compute body parts to swap *)
k = RigidBodyDynamics`Private`rb[Links, TreeForm];

(* get A *)
k = KeyValueMap[List, k];
(* naming convention allows for grouping of left and right *)
f = StringJoin@StringSplit[#[[1]], "_"|"-"|"."|" "][[-2;;-1]]&;
k = GroupBy[k, f];
k = k[[All, All, 2]];
k = If[Length@# == 1, Join[#,#], #]& /@ k;

(* initialize A *)
A = ConstantArray[0, {nq, nq}];
(A[[#[[1]], #[[2]]]] = A[[#[[2]], #[[1]]]] = 1)& /@ k;

(* fix A *)
(* ind1 = {{a, b}} makes A\[LeftDoubleBracket]a, b\[RightDoubleBracket] and A\[LeftDoubleBracket]b, a\[RightDoubleBracket] = -1, etc. *)
(* it's OK if a = b, but they must come in pairs *)
f = If[IntegerQ[#], #, RBDGetIndex@#]&;

I = Map[f, ind1, {2}];
Do[A[[Sequence@@i]] = A[[Sequence@@Reverse@i]] = -1, {i, I}];

I = Map[f, ind0, {2}];
Do[A[[Sequence@@i]] = A[[Sequence@@Reverse@i]] = 0, {i, I}];

ArrayFlatten[{{A, 0}, {0, A}}]
];


(* ::Input::Initialization:: *)
SetAttributes[{BLGetIndex, BLGetValue}, Listable];

Options[BLGetIndex] = {"m" -> Automatic, "n" -> 1, "x" -> Automatic};

BLGetIndex[i_Integer, o:OptionsPattern[]] := BLGetIndex[RBDGetValue[i], o];

BLGetIndex[s_String, o:OptionsPattern[]] := BLGetIndex[\[DoubleStruckQ][s, OptionValue["n"]], o];

BLGetIndex[q_, OptionsPattern[]] := Module[{n, m}, 
m = OptionValue["m"];
If[m === Automatic, m = BLbiped["m[0]"]];

n = OptionValue["x"];
Which[
n === Automatic, n = BLbiped["c", m, "x"],
!VectorQ[n, IntegerQ], n = BLRemoveStates@@n
];

n = Position[RBDGetValue@n, RBDGetValue@RBDGetIndex@q];
n = Flatten@n;
If[n === {}, n, First@n]
];

BLGetValue[i_, m0_:Automatic] := Module[{m, c, p, x, \[Lambda]},
m = If[m0 === Automatic, BLbiped["m[0]"], m0];

p = BLbiped["p", m, "x"];
c = BLbiped["c", m];
x = c["x"];
\[Lambda] = Flatten@Values@KeyDrop[c, "x"];

If[MemberQ[p, i], RBDGetValue@x[[i]], \[DoubleStruckC][\[Lambda][[i-Length@x]]]]
];


(* ::Input::Initialization:: *)
p2c::ncp = "No continuation parameters have been set.";
p2c[c_, n_] := Module[{ncp, f, v, r, d, Dc},
(* assume "p" is in absolute indexing order *)
ncp = Max@Lookup[BLbiped, "p", 0];

If[ncp > 0,
v = {{\[DoubleStruckC], ncp}};

Dc = {IdentityMatrix[ncp], ConstantArray[0, {ncp, ncp,ncp}]};
d = List@Derivatives`Private`CreateArguments[Evaluate@v[[All,1]], n];
d = MapIndexed[HoldPattern[#1] -> Dc[[#2[[1]]]]&, d[[2;;n+1]]];

f = N@First@Df[{{c}, v}, "ch", D->n] /. d;
f = DfToCompiledFunction[f, v, {_Real}, CompilationTarget -> "WVM"];

d = {Hold[Slot[1][[1]]], {}, {}};
r = With[{a = Sequence@@d[[1;;#2[[1]]]]}, Hold[#1][a]]&;
f = MapIndexed[r, f];
With[{a = f}, a&] /. Hold[a_] :> a,
Message[p2c::ncp];
{}&
]
];

c2c::nc = "No parameters have been set.";
c2c[c_, n_] := Module[{f, v, r, d, p},
If[nc > 0,
v = {{\[DoubleStruckX], nx}, {\[DoubleStruckC], nc}};
d = Table[p[Slot[i], j], {i, Length@v}, {j, n+1}];

f = N@First@Df[{{c}, v}, "ch", D->n];
f = DfToCompiledFunction[f, v, _Real, CompilationTarget -> "WVM"];

r = With[{a = Sequence@@Flatten@d[[All, 1;;#2[[1]]]]}, Hold[#1][a]]&;
f = MapIndexed[r, f];
With[{a = f}, a&] /. Hold[a_] :> a /. p -> Part,
Message[c2c::nc];
{}&
]
];


(* ::Input::Initialization:: *)
BLContinuationIndices[ap_:{}, dp_:{}] := Module[{a, n, m, p},
(* deprecated *)
Throw[BLContinuationIndices];
a = Flatten@angles;
a = Join[a, a+nq, ap];
a = DeleteCases[a, Alternatives@@dp];
n = Length@a;
p = ConstantArray[0, nc];
p[[a]] = Array[\[DoubleStruckC], n];
p[[nq+1]] = 1;

{a, p}
];

BLCreateContinuationParameters[begin_, CP_] := Module[{A, a, t, x},
(* flip order of keys, KeyValueMap flips, Assoc... make into list of <||> *)
A = (Keys@#2 -> (Association /@ Thread[#1 -> Values@#2]))&;
A = AssociationThread/@KeyValueMap[A, CP];
A = Merge[A, Join@@#&];

(* p *)
blmp[A[["\[DoubleStruckC]", All, "p"]]];
(* cT *)
blmcT[A[["\[DoubleStruckC]", All, "T"]]];

BLbiped["m[0]"] = begin;
BLbiped = Join[BLbiped, A];

(* update angles *)
BLSetAngles[];
];


(* ::Input::Initialization:: *)
BLLinearizedDynamics[m_, ceq_] := Module[{T, DT, mi, xi, ci, fi, Ai, I, x, eAt},
(* to (m-, x-, c-) *)
{mi, xi, ci} = BLmxcp[m, ceq];
xi = devec[xi, nx];
ci = devec[ci, nc];
DT = BLbiped["t", mi];
T = BLGetSwitchingTimes[ci, "m" -> mi, "DT" -> DT];

(* only phase variable changes along trajectory *)
I = {IdentityMatrix[nx], IdentityMatrix[{nc, nx}]};
x = {Prepend[xi[[1, 2;;]], #1], I[[1]]}&;
Ai = devec[BLbiped["f", mi][x[#], {ci[[1]], I[[2]]}], nx][[2]]&;

I = Reap[
Sow[mi, "m"];Sow[ci, "c"];Sow[xi, "x-"];Sow[xi, "x+"];
Do[
If[DT[[i]] != 0,
fi = devec[BLbiped["f", mi][xi, ci], nx];
xi[[2, All, DT[[i]]]] += fi[[1]];
];
Sow[xi, "x-"];

(* to (m+, x+, c+) *)
mi = BLbiped["m", mi][xi, ci];
xi = devec[BLbiped["h", mi][xi, ci], nx];
ci = devec[BLc[mi, xi, ci], nc];

If[DT[[i]] != 0,
fi = devec[BLbiped["f", mi][xi, ci], nx];
xi[[2, All, DT[[i]]]] -= fi[[1]];
];
Sow[mi, "m"];Sow[ci, "c"];Sow[xi, "x+"];

eAt = MatrixExp[Ai[T[[i+1]]](T[[i+1]]-T[[i]])];
xi[[2]] = eAt.xi[[2]];,
{i, Length@T-1}
];

If[DT[[-1]] != 0,
fi = devec[BLbiped["f", mi][xi, ci], nx];
xi[[2, All, DT[[-1]]]] += fi[[1]];
];
Sow[xi, "x-"];, _, Rule
];

x = BLbiped["c", m, "x"];
<|"R" -> xi[[All, x]]-ci[[All, x]], Rest@I, "T" -> T|>
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
