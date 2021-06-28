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
BeginPackage["GlobalVariables`"]

nq::usage = "Stores the number of configuration variables.";
nx::usage = "# of state variables; nx = 2nq";
nc::usage = "# of control/design parameters";

(* configurations, velocities, accelerations, state, parameters = \[Lambda] *)
\[DoubleStruckQ]::usage = "";
\[DoubleStruckV]::usage = "";
\[DoubleStruckA]::usage = "";
\[DoubleStruckX]::usage = "";

(* state-time-control parameters *)
\[DoubleStruckC]::usage = "";

(* spatial position = {rx, ry, rz, px, py, pz} *)
\[DoubleStruckB]::usage = "";

Begin["Private`"]
Unprotect[\[DoubleStruckB]];
Options[\[DoubleStruckB]] = {"o" -> Root, "a" -> Root};
SetAttributes[{\[DoubleStruckQ], \[DoubleStruckV], \[DoubleStruckA], \[DoubleStruckX], \[DoubleStruckC], \[DoubleStruckB]},{Protected, NHoldAll}];


(* ::Input::Initialization:: *)
End[]
EndPackage[]
