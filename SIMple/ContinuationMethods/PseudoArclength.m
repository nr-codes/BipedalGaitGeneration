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



(* ::Code::Initialization:: *)
(*
ContinuationMethods.nb: An implementation of various continuation methods.
Copyright (C) 2014 Nelson Rosa Jr.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version. This program is distributed in the 
hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details. You should have 
received a copy of the GNU General Public License along with this program.
If not, see <http://www.gnu.org/licenses/>.
*)


(* ::Input::Initialization:: *)
BeginPackage["ContinuationMethods`"]

cmc::usage = "";

cmarmijo::usage = "";

Begin["`Private`"]


(* ::Input::Initialization:: *)
(* C = {c, NS, h, ...} *)
ic = 1;
ins = 2;
ih = 3;
iC = {ic, ins};

(* stopping criterion for adaptive step size *)
htol = 10^-10;
{kder, dder, ader} = {3.0, 0.5, 0.05};


(* ::Input::Initialization:: *)
Options[cmc] = {"newton" -> {}};

cmc[z_, z0_, C0_, opts:OptionsPattern[]] := Module[{c, r, dr, NS, h, d},
(* prediction *)
h = C0[[ih]];
d = h (z-z0);
NS = C0[[ins]];
c = C0[[ic]] + d.NS;

(* correction *)
{c, r, dr} = newton[c, d, NS, OptionValue["newton"]];
NS = ns[c, r, dr, NS];

{c, NS, h}
];


(* ::Input::Initialization:: *)
cmarmijo::ls = "Could not satisfy sufficient decrease condition for `` after `` iterations.";

cmarmijo::f = "The value of the objective function at z0 = `` is very small.  Minimum (or root) found.  Final cost is ``.";

cmarmijo::g = "The norm of the gradient (``) at z0 = `` is very small.  Extremum (minmum or maximum) found.  Final cost is ``.";

Options[cmarmijo] = {
"newton" -> {},

"\[Alpha]" -> 10^-4, 
"\[Beta]" -> 0.5, 
"min" -> 1,
"max" -> 20, 

"hmin" -> -\[Infinity],
"hmax" -> \[Infinity],

"f" -> ({0, {0}, {{0}}}&), 
"gtol" -> 10^-8, 
"ftol" -> 10^-8,
Root -> True,

Method-> cmc, 
"cm" -> {}, 
Print -> False, 
Abort -> True
};

armmsg = StringTemplate["    `` (``/``) --- f: `` (``) \[Lambda]: `` armijo: ``"];

cmarmijo[z_, z0_, C0_, opts:OptionsPattern[]] := Module[{cm, o, M, f0, g0, H0, h0, \[Alpha], \[Beta], N0, Carm, MIN, MAX, a, \[Lambda], C, f, m, msg, h, hmin, hmax},
(* continuation parameters *)
cm = OptionValue[Method];
o = OptionValue["cm"];

(* get c and dc/ds (and eventually d^2c/ds^2) *)

(* M: M(c(s), d/ds c(s), d^2/ds^2 c(s)) *)
M = OptionValue["f"]; (* f, Df, (and eventually D2f) *)

(* M = {f, df/dc, (and eventually D2f(c)) *)
{f0, g0, H0} = M[C0[[ic]]];

(*Print["f0: ", f0, " g0: ", g0, " H0: ", H0];*)

(* is z0 a minimizer or root? *)
If[f0 < OptionValue["ftol"], 
Message[cmarmijo::f, z0, f0];
Throw[$Failed]
];

(* get derivatives of f w.r.t arclength using chain rule *)
If[OptionValue[Root],
(* root finding, H = df/dc dc/ds *)
msg = "root";
H0 = H0.C0[[ins]]\[Transpose];,
(* minimization, g = df/dc dc/ds *)
msg = "min";
g0 = g0.C0[[ins]]\[Transpose];
H0 = IdentityMatrix[Length@g0];
];

(*Print["g0: ", g0, " H0: ", H0];*)

(* compute descent direction in s's space *)
h0 = -LinearSolve[H0, g0];
If[Norm[h0] < OptionValue["gtol"], 
Message[cmarmijo::g, Norm[h0], z0, ScientificForm[f0]];
Throw[$Failed]
];

(*Print["h0: ", h0];*)

(* cmarmijo line search parameters *)
\[Alpha] = OptionValue["\[Alpha]"];
\[Beta] = OptionValue["\[Beta]"];
N0 = g0.h0;

(* take a Newton step? MIN = 0 can lead to jumps in c(s) *)
(* unsure if these jumps land c(s) on a different manifold *)
(* unsure if this matters *)
MIN = OptionValue["min"];
MAX = OptionValue["max"];

(* guard against large step sizes *)
hmin = OptionValue["hmin"];
hmax = OptionValue["hmax"];

(* for f(c(s)), we preform a line search in s *)
a = False;
Carm = C0;
Carm[[ins]] = Normalize /@ Carm[[ins]];

(*Print["C0: ", Carm\[LeftDoubleBracket]ic, -4;;-1\[RightDoubleBracket]];*)
(*Print["NS: ", Carm\[LeftDoubleBracket]ins\[RightDoubleBracket], " : ", h0];*)

Do[
(* line search *)
\[Lambda] = \[Beta]^m;
Carm[[ih]] = Min[Max[#, hmin], hmax]& /@ (\[Lambda] h0);
C = Catch[cm[z, z0, Carm, o]];
If[C === $Failed, 
If[Mod[m, OptionValue[Print]] === 0, 
Print[armmsg[msg, m, MAX, $Failed, f0, \[Lambda], False]];
];
Continue[]
];

(* cmarmijo line search *)
f = First@M[C[[ic]]];
a = f - f0 <= -\[Alpha] \[Lambda] N0;

If[Mod[m, OptionValue[Print]] === 0, 
Print[armmsg[msg, m, MAX, f, f0, \[Lambda], a]];
];

If[a, Break[]];,
{m, MIN, MAX}
];

(* adds cost *)
If[C =!= $Failed, C = Append[C, f];];

If[a, C, Message[cmarmijo::ls, z, MAX];Throw@$Failed]
];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
