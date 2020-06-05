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
PackageVariables.nb: Lists global variables used by the NLinks package.
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
BeginPackage["RigidBodyDynamics`", "GlobalVariables`"]
Begin["`Private`"]


(* ::Input::Initialization:: *)
ufun = zq&;


(* ::Input::Initialization:: *)
RBDb[x_:{}, \[Lambda]_:{}] := Module[{},
qd = If[x === {}, Array[\[DoubleStruckX], nq, nq+1], x[[nq+1;;nx]]];
qdd = zq;

ag = agfun[];
s = sfun[x, \[Lambda]];
sdot = sdotfun[x, \[Lambda]];
XL = XLfun[x, \[Lambda]];
\[DoubleStruckCapitalI] = \[DoubleStruckCapitalI]fun[x, \[Lambda]];
RNEA[];
uJ
];

RBDM[x_:{}, \[Lambda]_:{}] := Module[{},
s = sfun[x, \[Lambda]];
XL = XLfun[x, \[Lambda]];
\[DoubleStruckCapitalI] = \[DoubleStruckCapitalI]fun[x, \[Lambda]];
CRB[];
M
];

RBDqdd[x_:{}, \[Lambda]_:{}] := Module[{},
qd = If[x === {}, Array[\[DoubleStruckX], nq, nq+1], x[[nq+1;;nx]]];

ag = agfun[x, \[Lambda]];
s = sfun[x, \[Lambda]];
sdot = sdotfun[x, \[Lambda]];
XL = XLfun[x, \[Lambda]];
\[DoubleStruckCapitalI] = \[DoubleStruckCapitalI]fun[x, \[Lambda]];
u = ufun[x, \[Lambda]];
ABA[];
qdd
];


(* ::Input::Initialization:: *)
RBDJ[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
s = sfun[x, \[Lambda]];
sdot = sdotfun[x, \[Lambda]];
XL = XLfun[x, \[Lambda]];

r = rfun[x, \[Lambda]];
rdot = rdotfun[x, \[Lambda]];
Tcb = Tcbfun[x, \[Lambda]];
J = Jfun[x, \[Lambda]];
\[Phi] = \[Phi]fun[x, \[Lambda]];
\[Eta] = \[Eta]fun[x, \[Lambda]];
K = Kfun[x, \[Lambda]];

bo = rb[C, "bo"];
ba = rb[C, "ba"];
bs = rb[C, "bs"];
bx = rb[C, "bx"];

(* for computing Xdot *)
qd = If[x === {}, Array[\[DoubleStruckX], nq, nq+1], x[[nq+1;;nx]]];

V[];
X0[];
rs0[];
JOSIM[];
{J, \[Phi]}
];


(* ::Input::Initialization:: *)
RBDEOM[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
pcons = rb[C, "p"];
vcons = rb[C, "v"];
ucons = rb[C, "u"];

u = ufun[x, \[Lambda]];
RBDM[x, \[Lambda]];
RBDb[x, \[Lambda]];
RBDJ[x, \[Lambda]];
EOM[];

Ab
];


(* ::Input::Initialization:: *)
RBDIME[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
pcons = rb[C, "p"];
vcons = rb[C, "v"];
ucons = rb[C, "u"];

RBDM[x, \[Lambda]];
RBDJ[x, \[Lambda]];
IME[];

Ab
];


(* ::Input::Initialization:: *)
RBDMQ[x_:{}, \[Lambda]_:{}] := Module[{p, vJ},
qd = If[x === {}, Array[\[DoubleStruckX], nq, nq+1], x[[nq+1;;nx]]];
qdd = zq;

ag = agfun[x, \[Lambda]];
s = sfun[x, \[Lambda]];
XL = XLfun[x, \[Lambda]];
\[DoubleStruckCapitalI] = \[DoubleStruckCapitalI]fun[x, \[Lambda]];

RBDMechanicalQuantities[]
];


(* ::Input::Initialization:: *)
End[];
EndPackage[]
