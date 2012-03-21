(* Theorema 
    Copyright (C) 2010 The Theorema Group

    This file is part of Theorema.2
    
    Theorema.2 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Theorema.2 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)

BeginPackage["Theorema`Interface`GUI`"];
(* Exported symbols added here with SymbolName::usage *)  

Needs["Theorema`Common`"]
Needs["Theorema`Provers`"]
Needs["Theorema`Interface`Language`"]

Begin["`Private`"] (* Begin Private Context *) 


(* ::Section:: *)
(* initGUI *)

initGUI[] := 
	Module[{ tc},
		(*
		   In $tmaBuiltins
		   o) nesting gives the nested structure for display
		   o) each entry has the form
		      {key, box display, default active for proving, default active for computation, default active for solving},
		      where "key" is the corresponding key used in activeComputation *)
        $tmaBuiltins = {
        	{"Sets", 
        		{"SetEqual", RowBox[{"A","=","B"}], False, False, False},
           		{"Union", RowBox[{"A","\[Union]","B"}], False, False, False},
        		{"Intersection", RowBox[{"A","\[Intersection]","B"}], False, False, False},
        		{"SequenceOf", RowBox[{"{","\[Ellipsis]", "|", "\[Ellipsis]", "}"}], False, False, False}},
        	{"Tuples",
        		{"SequenceOf", RowBox[{"\[LeftAngleBracket]","\[Ellipsis]", "|", "\[Ellipsis]", "\[RightAngleBracket]"}], False, False, False}},
        	{"Arithmetic", 
        		{"Plus", RowBox[{"A","+","B"}], False, True, False},
        		{"Times", RowBox[{"A","*","B"}], False, True, False},
        		{"Equal", RowBox[{"A","=","B"}], False, False, False},
        		{"Less", RowBox[{"A","<","B"}], False, True, False},
        		{"LessEqual", RowBox[{"A","\[LessEqual]","B"}], False, True, False},
        		{"Greater", RowBox[{"A",">","B"}], False, True, False},
        		{"GreaterEqual", RowBox[{"A","\[GreaterEqual]","B"}], False, True, False}},
        	{"Logic", 
        		{"Not", RowBox[{"\[Not]","P"}], False, True, False},
        		{"And", RowBox[{"P", "\[And]","Q"}], False, True, False},
        		{"Or", RowBox[{"P", "\[Or]","Q"}], False, True, False},
        		{"Implies", RowBox[{"P", "\[Implies]","Q"}], False, True, False},
        		{"Iff", RowBox[{"P", "\[Equivalent]","Q"}], False, True, False},
        		{"Forall", RowBox[{"\[ForAll]","P"}], False, True, False},
        		{"Exists", RowBox[{"\[Exists]","P"}], False, True, False},
        		{"Equal", RowBox[{"A","=","B"}], False, False, False}},
        	{"Programming",
        		{"Module", RowBox[{"Module","[","\[Ellipsis]","]"}], False, True, False},
        		{"Do", RowBox[{"Do","[","\[Ellipsis]","]"}], False, True, False},
        		{"While", RowBox[{"While","[","\[Ellipsis]","]"}], False, True, False},
        		{"For", RowBox[{"For","[","\[Ellipsis]","]"}], False, True, False},
        		{"Which", RowBox[{"Which","[","\[Ellipsis]","]"}], False, True, False},
        		{"Switch", RowBox[{"Switch","[","\[Ellipsis]","]"}], False, True, False}}
        };
		$kbStruct = {};
		$initLabel = "???";
		$labelSeparator = ",";
		$cellTagKeySeparator = ":";
		If[ ValueQ[$theoremaGUI], tc = "Theorema Commander" /. $theoremaGUI];
		If[ $Notebooks && MemberQ[Notebooks[], tc], NotebookClose[tc]];
		Clear[ kbSelectProve, kbSelectSolve];
		kbSelectProve[_] := False;
		kbSelectSolve[_] := False;
		$selectedProofGoal = {};
		$selectedSearchDepth = 30;
		$maxSearchDepth = 200;
		initBuiltins[ {"prove", "compute", "solve"}];
		$theoremaGUI = {"Theorema Commander" -> theoremaCommander[]};
	]

initBuiltins[ l_List] :=
    Module[ {bui},
        bui = Cases[ $tmaBuiltins, {_String, _, _Symbol, _Symbol, _Symbol}, Infinity];
        If[ MemberQ[ l, "prove"],
            Scan[ (Theorema`Computation`Language`Private`buiActProve[#[[1]]] = #[[3]])&, bui]
        ];
        If[ MemberQ[ l, "compute"],
            Scan[ (Theorema`Computation`Language`Private`buiActComputation[#[[1]]] = #[[4]])&, bui]
        ];
        If[ MemberQ[ l, "solve"],
            Scan[ (Theorema`Computation`Language`Private`buiActSolve[#[[1]]] = #[[5]])&, bui]
        ];
    ]
initBuiltins[ args___] := unexpected[ initBuiltins, {args}]

(* ::Section:: *)
(* theoremaCommander *)

theoremaCommander[] /; $Notebooks :=
    Module[ {style = Replace[ ScreenStyleEnvironment, Options[InputNotebook[], ScreenStyleEnvironment]]},
        CreatePalette[ Dynamic[Refresh[
        	TabView[{
        		translate["tcLangTabLabel"]->TabView[{
        			translate["tcLangTabEnvTabLabel"]->envButtons[],
        			translate["tcLangTabMathTabLabel"]->Dynamic[Refresh[ langButtons[], TrackedSymbols :> {$buttonNat}]],
        			translate["tcLangTabArchTabLabel"]->archButtons[]}, Dynamic[$tcLangTab],
        			LabelStyle->"TabLabel2", ControlPlacement->Top],
        		translate["tcProveTabLabel"]->TabView[{
        			translate["tcProveTabGoalTabLabel"]->Dynamic[ Refresh[ displaySelectedGoal[], UpdateInterval -> 2]],
        			translate["tcProveTabKBTabLabel"]->Dynamic[Refresh[displayKBBrowser["prove"], TrackedSymbols :> {$kbStruct}]],
        			translate["tcProveTabBuiltinTabLabel"]->displayBuiltinBrowser["prove"],
        			translate["tcProveTabProverTabLabel"]->Dynamic[ Refresh[ selectProver[], TrackedSymbols :> {$selectedRuleSet, $selectedStrategy}]],
        			translate["tcProveTabSubmitTabLabel"]->Dynamic[ Refresh[ submitProveTask[ $tcProveTab],
        				TrackedSymbols :> {$tcProveTab, $selectedProofGoal, $selectedProofKB, $selectedProver}]],
        			translate["tcProveTabNavigateTabLabel"]->Dynamic[ Refresh[ proofNavigation[ $TMAproofTree],
        				TrackedSymbols :> {$TMAproofTree}]]}, Dynamic[$tcProveTab],
        			LabelStyle->"TabLabel2", ControlPlacement->Top],
        		translate["tcComputeTabLabel"]->TabView[{
        			translate["tcComputeTabSetupTabLabel"]->Dynamic[Refresh[ compSetup[], TrackedSymbols :> {$buttonNat}]],
        			translate["tcComputeTabKBTabLabel"]->Dynamic[Refresh[displayKBBrowser["compute"], TrackedSymbols :> {$kbStruct}]],
        			translate["tcComputeTabBuiltinTabLabel"]->displayBuiltinBrowser["compute"]}, Dynamic[$tcCompTab],
        			LabelStyle->"TabLabel2", ControlPlacement->Top],
        		translate["tcSolveTabLabel"]->TabView[{
        			translate["tcSolveTabKBTabLabel"]->Dynamic[Refresh[displayKBBrowser["solve"], TrackedSymbols :> {$kbStruct}]],
        			translate["tcSolveTabBuiltinTabLabel"]->displayBuiltinBrowser["solve"]}, Dynamic[$tcSolveTab],
        			LabelStyle->"TabLabel2", ControlPlacement->Top],
        		translate["tcPreferencesTabLabel"]->TabView[{
        			translate["tcPrefLanguage"]->PopupMenu[Dynamic[$Language], availableLanguages[]],
        			translate["tcPrefArchiveDir"]->Row[{Dynamic[Tooltip[ToFileName[Take[FileNameSplit[$TheoremaArchiveDirectory], -2]], $TheoremaArchiveDirectory]],
        				FileNameSetter[Dynamic[$TheoremaArchiveDirectory], "Directory"]}, Spacer[10]]},
        			LabelStyle->"TabLabel2", ControlPlacement->Top]},
        		Dynamic[$tcTopLevelTab],
        		LabelStyle->"TabLabel1", ControlPlacement->Left
        	], TrackedSymbols :> {$Language}]],
        	StyleDefinitions -> ToFileName[{"Theorema"}, "GUI.nb"],
        	WindowTitle -> translate["Theorema Commander"],
        	ScreenStyleEnvironment -> style,
        	WindowElements -> {"StatusArea"}]
    ]

emptyPane[ text_String:""] := Pane[ text, Alignment -> {Center, Center}]
emptyPane[ text_String:"", size_] := Pane[ text, size, Alignment -> {Left, Top}]
emptyPane[ args___] := unexpected[ emptyPane, {args}]

(* ::Subsubsection:: *)
(* displaySelectedGoal *)
   
displaySelectedGoal[ ] :=
    Module[ { sel, goal},
    	$proofInitNotebook = InputNotebook[];
    	sel = NotebookRead[ $proofInitNotebook];
    	goal = findSelectedFormula[ sel];
        If[ goal === {},
            emptyPane[ translate["noGoal"], 350],
            With[ {selGoal = goal[[1]]},
            	Pane[ Column[ {
            		Row[ displayLabeledFormula[ selGoal], Spacer[5]],
            		Button[ translate[ "OKnext"], $selectedProofGoal = selGoal; $tcProveTab++]}], 350, ImageSizeAction -> "Scrollable", Scrollbars -> Automatic]
            ]
        ]
    ]
displaySelectedGoal[ goal_] :=
    Module[ { },
        If[ goal === {},
            emptyPane[ translate["noGoal"], 350],
            Pane[ Row[ displayLabeledFormula[ goal], Spacer[5]], 350, ImageSizeAction -> "Scrollable", Scrollbars -> Automatic]
        ]
    ]
displaySelectedGoal[args___] :=
    unexpected[displaySelectedGoal, {args}]

displayLabeledFormula[ {key_, form_, lab_}] := 
	Module[ {link},
		link = { StringReplace[ key[[2]], "Source"<>$cellTagKeySeparator -> "", 1], key[[1]]};
		{Hyperlink[ Style[ lab, "FormulaLabel"], link], Style[ theoremaDisplay[ form], "DisplayFormula"]}
	]
displayLabeledFormula[ args___] := unexpected[ displayLabeledFormula, {args}]

displaySelectedKB[ ] :=
	Module[ {},
    	$selectedProofKB = Select[ $tmaEnv, kbSelectProve[#[[1]]]&];
        If[ $selectedProofKB === {},
            emptyPane[ translate["noKB"], {350, 350}],
            Pane[ Grid[ displayLabeledFormulaList[ $selectedProofKB]], {350, 350}, ImageSizeAction -> "Scrollable", Scrollbars -> Automatic]
        ]
    ]
displaySelectedKB[ args___] := unexpected[ displaySelectedKB, {args}]

displayLabeledFormulaList[ l_List] := Map[ displayLabeledFormula, l]
displayLabeledFormulaList[ args___] := unexpected[ displayLabeledFormulaList, {args}]

 
(* ::Subsubsection:: *)
(* extractKBStruct *)
(*
extract hierarchically structured knowledge from a notebook
*)

extractKBStruct[nb_NotebookObject] := extractKBStruct[ NotebookGet[nb]];

extractKBStruct[nb_Notebook] :=
    Module[ {posTit = Cases[Position[nb, Cell[_, "Title", ___]], {a___, 1}],
      posSec =  Cases[Position[nb, Cell[_, "Section", ___]], {a___, 1}], 
      posSubsec = Cases[Position[nb, Cell[_, "Subsection", ___]], {a___, 1}], 
      posSubsubsec = Cases[Position[nb, Cell[_, "Subsubsection", ___]], {a___, 1}], 
      posSubsubsubsec = Cases[Position[nb, Cell[_, "Subsubsubsection", ___]], {a___, 1}], 
      posEnv = Cases[Position[nb, Cell[_, "OpenEnvironment", ___]], {a___, 1}], 
      posInp = Position[nb, Cell[_, "FormalTextInputFormula", ___]], inputs, depth, sub, root, heads, isolated},
      (* extract all positions of relevant cells
         join possible containers with decreasing level of nesting *)
        heads = Join[posEnv, posSubsubsubsec, posSubsubsec, posSubsec, posSec, posTit];
        (* build up a nested list structure representing the nested cell structure 
           start with singleton lists containing a header and add input cells to the respective group *)
        {inputs, isolated} = Fold[arrangeInput, {Map[List, heads], {}}, posInp];
        depth = Union[Map[Length[#[[1]]] &, inputs]];
        (* go through all groups starting with the most deeply nested one *)
        While[Length[depth] > 1,
            (* the most deeply nested ones are the possible candidates to be joined to other groups *)
         sub = Select[inputs, Length[#[[1]]] == depth[[-1]] &];
         (* the less deeply nested ones are groups to which subitems may be added *)
         root = Select[inputs, Length[#[[1]]] < depth[[-1]] &];
         (* one after the other add lower priority groups to higher priority ones *)
         inputs = Fold[arrangeSub, root, sub];
         depth = Drop[depth, -1];
         ];
         (* finally, add isolated nodes at the beginning *)
        Join[isolated, inputs]
    ]

extractKBStruct[args___] :=
    unexpected[extractKBStruct, {args}]


(* ::Subsubsection:: *)
(* arrange items *)

arrangeInput[{struct_, isolated_}, item_] :=
(* given a structured list and a list of isolated items,
   add a new input cell item at the appropriate position
   struct is a list of lists, each sublist represents a group and starts with the group header,
   each entry is a position specification list
   groups are sorted so that low-level groups come first *)
    Module[ {l, root, pos},
    	(* go through all groups to find the one on the right level *)
        pos = Do[
          root = Drop[struct[[i, 1]], -1];
          l = Length[root];
          (* if the position specification of a group header (dropping its last position)
             coincides with the starting part of the item, then this is the right group,
             i.e. the closest enclosing group *)
          If[ Length[item] > l && Take[item, l] == root,
              Return[i]
          ],
          {i, Length[struct]}];
          (* if we have found a fitting group (Return[i] from the loop) we insert 
             at the end in that group, otherwise we add to the list of isolated nodes *)
        If[ NumberQ[pos],
            {Insert[struct, item, {pos, -1}], isolated},
            {struct, Insert[isolated, {item}, -1]}
        ]
    ]
arrangeInput[args___] := unexpected[arrangeInput, {args}]

arrangeSub[struct_, item : {head_, ___}] :=
(* given a structured list,
   add a group item at the appropriate position
   struct is a list of lists, each sublist represents a group and starts with the group header,
   each entry is a position specification list
   groups are sorted so that low-level groups come first   
   Works like arrangeInput, only that we compare by taking the group header representing the item *)
    Module[ {l, root, pos},
    	(* go through all groups to find the one on the right level *)
        pos = Do[
          root = Drop[struct[[i, 1]], -1];
          l = Length[root];
          If[ Length[head] > l && Take[head, l] == root,
              Return[i]
          ],
          {i, Length[struct]}];
          (* if we have found a fitting group (Return[i] from the loop) we insert 
             into that group keeping the sorted order, otherwise make a new group and insert it at the beginning *)
        If[ NumberQ[pos],
            insertSorted[struct, item, pos],
            Insert[struct, {item}, 1]
        ]
    ]
arrangeSub[args___] := unexpected[arrangeSub, {args}]

insertSorted[struct_, item:{head_, ___}, pos_Integer] :=
(* insert item into the sorted list that occurs at position pos in struct *)
    Module[ {p = -1, h},
        Do[
        	(* go through all elements in the sublist at position pos
        	   if an element is a list of integers it represents a position,
        	   otherwise it represents a group of positions, and we select the group header at position 1 *)
            If[ !MatchQ[ h = struct[[pos, i]], {__Integer}],
                h = h[[1]]
            ];
            (* we compare the last entry in the position spec: if the elements pos is greater than the item's
               then we need to insert before that one *)
            If[ h[[ Length[h]]] > head[[ Length[h]]],
                p = i;
                Return[]
            ],
        (* we start comparing at position 2 because we never insert before the group header *)
        {i, 2, Length[struct[[pos]]]}];
        (* if we haven't found a position (Return[i] in the loop) then we insert at position -1, i.e. at the end *)
        Insert[ struct, item, {pos, p}]
    ]
insertSorted[args___] := unexpected[insertSorted, {args}]


(* ::Subsubsection:: *)
(* structView *)
Clear[structView];

(* produce a list containing the structured view corresponding to notebook file and a list of all cell tags contained
   recursively process the nested list structure generated by extractKBStruct 
   parameter 'task' decides whether the view is generated for the prove tab or the compute tab *)
   
(* group with header and content *)   
structView[file_, {head:Cell[sec_, "Title"|"Section"|"Subsection"|"Subsubsection"|"Subsubsubsection"|"OpenEnvironment", opts___], rest__}, tags_, task_] :=
    Module[ {sub, compTags},
    	(* process content componentwise
    	   during recursion, we collect all cell tags from cells contained in that group 
    	   Transpose -> pos 1 contains the list of subviews
    	   pos 2 contains the list of tags in subgroups *)
        sub = Transpose[Map[structView[file, #, tags, task] &, {rest}]];
        compTags = Apply[Union, sub[[2]]];
        (* generate an opener view with the view of the header and the content as a column
           a global symbol with unique name is generated, whose value stores the state of the opener *)
        {OpenerView[{headerView[file, head, compTags, task], Column[sub[[1]]]}, 
        	ToExpression[StringReplace["Dynamic[NEWSYM]", 
        		"NEWSYM" -> "$kbStructState$"<>ToString[Hash[FileBaseName[file]]]<>"$"<>ToString[CellID/.{opts}]]]], 
         compTags}
    ]
    
(* group with header and no content -> ignore *)   
structView[file_, {Cell[sec_, "Title"|"Section"|"Subsection"|"Subsubsection"|"Subsubsubsection"|"OpenEnvironment", ___]}, tags_, task_] :=
	Sequence[]

(* list processed componentwise *) 
structView[file_, item_List, tags_, task_] :=
    Module[ {sub, compTags},
     	(* process content componentwise
    	   during recursion, we collect all cell tags from cells contained in that group 
    	   Transpose -> pos 1 contains the list of subviews
    	   pos 2 contains the list of tags in subgroups *)
        sub = Transpose[Map[structView[file, #, tags, task] &, item]];
        compTags = Apply[Union, sub[[2]]];
        (* generate a column and return the collected tags also *)
        {Column[sub[[1]]], compTags}
    ]
  
(* input cell with cell tags *)
structView[file_, Cell[content_, "FormalTextInputFormula", a___, CellTags -> cellTags_, b___], 
  tags_, task_] :=
    Module[ { isEval, formPos, cleanCellTags, keyTags, formulaLabel, idLabel, nbAvail},
        cleanCellTags = getCleanCellTags[ cellTags];
        (* keyTags are those cell tags that are used to uniquely identify the formula in the KB *)
        keyTags = getKeyTags[ cellTags];
        (* check whether cell has been evaluated -> formula is in KB? *)
        formPos = Position[ $tmaEnv, {keyTags, _, _}, 1, 1];
        isEval = formPos =!= {};
        (* Join list of CellTags, use $labelSeparator. *)
        If[ cleanCellTags === {},
            formulaLabel = cellTagsToString[ cellTags];
			idLabel = formulaLabel,
            formulaLabel = cellTagsToString[ cleanCellTags];
			idLabel = getCellIDLabel[ keyTags];
        ];
        (*
        If we load an archive without corresponding notebook available, then $kbStruct contains the archive name instead of the notebook name.
        Hence, 'file' will then be the archive instead of the notebook.
        Instead of hyperlinking into the notebook, we then present a window showing the original cell content. *)
        nbAvail = FileExistsQ[file] && FileExtension[file]==="nb";
        (* generate a checkbox and display the label
           checkbox sets the value of the global function kbSelectProve[labels] (activeComputationKB[labels] resp. for the compute tab),
           enabled only if the formula has been evaluated 
           label is a hyperlink to the notebook or a button that opens a new window displaying the formula *)
        {Switch[ task,
            "prove",
            Row[{Checkbox[Dynamic[kbSelectProve["KEY"]], Enabled->isEval] /. "KEY" -> keyTags, 
                If[ nbAvail,
                    Tooltip[ Hyperlink[ Style[formulaLabel, If[ isEval,
                                                       "FormalTextInputFormula",
                                                       "FormalTextInputFormulaUneval"
                                                   ]], {file, idLabel}],
                             If[ isEval,
                             	theoremaDisplay[ Extract[ $tmaEnv, Append[ formPos[[1]], 2]]],
                             	displayCellContent[ content]]
                    ],
                    With[ {magOpt = Options[ Replace[ "Theorema Commander", $theoremaGUI], Magnification]},
                    	Button[ Style[formulaLabel, "FormalTextInputFormula"], 
                        	CreateDialog[{Cell[ content, "Output"], CancelButton[ translate[ "OK"], NotebookClose[ButtonNotebook[]]]}, First[ magOpt]],
                        	Appearance -> None]
                    ]
                ]},
                Spacer[10]],
            "compute",
            Row[{Checkbox[Dynamic[Theorema`Computation`Language`Private`activeComputationKB["KEY"]], Enabled->isEval] /. "KEY" -> keyTags,
                If[ nbAvail,
                    Tooltip[ Hyperlink[ Style[formulaLabel, If[ isEval,
                                                       "FormalTextInputFormula",
                                                       "FormalTextInputFormulaUneval"
                                                   ]], {file, idLabel}],
                             If[ isEval,
                             	theoremaDisplay[ Extract[ $tmaEnv, Append[ formPos[[1]], 2]]],
                             	displayCellContent[ content]]
                    ],
                    With[ {magOpt = Options[ Replace[ "Theorema Commander", $theoremaGUI], Magnification]},
                    	Button[ Style[formulaLabel, "FormalTextInputFormula"], 
                        	CreateDialog[{Cell[ content, "Output"], CancelButton[ translate[ "OK"], NotebookClose[ButtonNotebook[]]]}, First[ magOpt]],
                        	Appearance -> None]
                    ]
                ]},
                Spacer[10]],
            "solve",
            Row[{Checkbox[Dynamic[kbSelectSolve["KEY"]], Enabled->isEval] /. "KEY" -> keyTags, 
                If[ nbAvail,
                    Tooltip[ Hyperlink[ Style[formulaLabel, If[ isEval,
                                                       "FormalTextInputFormula",
                                                       "FormalTextInputFormulaUneval"
                                                   ]], {file, idLabel}],
                             If[ isEval,
                             	theoremaDisplay[ Extract[ $tmaEnv, Append[ formPos[[1]], 2]]],
                             	displayCellContent[ content]]
                    ],
                    With[ {magOpt = Options[ Replace[ "Theorema Commander", $theoremaGUI], Magnification]},
                    	Button[ Style[formulaLabel, "FormalTextInputFormula"], 
                        	CreateDialog[{Cell[ content, "Output"], CancelButton[ translate[ "OK"], NotebookClose[ButtonNotebook[]]]}, First[ magOpt]],
                        	Appearance -> None]
                    ]
                ]},
                Spacer[10]]    
            ], {keyTags}}
    ]

(* input cell without cell tags -> ignore *)
structView[file_, Cell[content_, "FormalTextInputFormula", ___], tags_, task_] :=
    Sequence[]

structView[args___] :=
    unexpected[structView, {args}]

(* header view *)
headerView[file_, Cell[ content_String, style_, ___], tags_, task_] :=
(* tags contains all tags contained in the group
   generate a checkbox for the whole group and the header from the cell
   checkbox does not have an associated variable whose value the box represents
   instead, the checkbox is checked if all tags containd in the group are checked,
   checking the box calls function setAll in order to set/unset all tags contained in the group *)
    Switch[ task,
    	"prove",
        Row[{Checkbox[Dynamic[allTrue[tags, kbSelectProve], setAll[tags, kbSelectProve, #] &]], Style[ content, style]}, Spacer[10]],
        "compute",
        Row[{Checkbox[Dynamic[allTrue[tags, Theorema`Computation`Language`Private`activeComputationKB], setAll[tags, Theorema`Computation`Language`Private`activeComputationKB, #] &]], Style[ content, style]}, Spacer[10]],
        "solve",
        Row[{Checkbox[Dynamic[allTrue[tags, kbSelectSolve], setAll[tags, kbSelectSolve, #] &]], Style[ content, style]}, Spacer[10]]        
    ]
headerView[args___] :=
    unexpected[headerView, {args}]

displayCellContent[ BoxData[ b_]] := DisplayForm[ b]
displayCellContent[ c_] := DisplayForm[ c]
displayCellContent[ args___] := unexpected[ displayCellContent, {args}]


(* ::Subsubsection:: *)
(* updateKBBrowser *)

(* global variable $kbStruct contains the knowledge structure
   for each notebook ever evaluated in the session it contains an entry
   filename -> struct, where
   filename is the full filename of the notebook and
   struct is the nested cell structure containing the cells at those positions obtained by extractKBStruct *)
updateKBBrowser[] :=
    Module[ {file=CurrentValue["NotebookFullFileName"], pos, new},
        pos = Position[ $kbStruct, file -> _];
        new = file -> With[ {nb = NotebookGet[EvaluationNotebook[]]},
                          extractKBStruct[nb] /. l_?VectorQ :> Extract[nb, l]
                      ];
        (* if there is already an entry for that notebook then replace the structure,
           otherwise add new entry *)
        If[ pos === {},
            AppendTo[ $kbStruct, new],
            $kbStruct[[pos[[1,1]]]] = new
        ]
    ]
updateKBBrowser[args___] :=
    unexpected[updateKBBrowser, {args}]


(* ::Subsubsection:: *)
(* displayKBBrowser *)
   
displayKBBrowser[ task_String] :=
    Module[ {},
        If[ $kbStruct === {},
            emptyPane[translate["noKnowl"]],
            (* generate tabs for each notebook,
               tab label contains a short form of the filename, tab contains a Pane containing the structured view *)
            TabView[
                  Map[Tooltip[Style[FileBaseName[#[[1]]], "NotebookName"], #[[1]]] -> 
                     Pane[structView[#[[1]], #[[2]], {}, task][[1]],
                      ImageSizeAction -> "Scrollable", Scrollbars -> Automatic] &, 
                   $kbStruct], 
                  Appearance -> {"Limited", 10}, FrameMargins->None]
        ]
    ]
displayKBBrowser[args___] :=
    unexpected[displayKBBrowser, {args}]

(* ::Subsubsection:: *)
(* structViewBuiltin *)
Clear[structViewBuiltin];

(* structured view for builtin operators
   follows the ideas of the structured view of the KB *)
   
structViewBuiltin[{category_String, rest__List}, tags_, task_String] :=
    Module[ {sub, compTags},
        sub = Transpose[Map[structViewBuiltin[#, tags, task] &, {rest}]];
        compTags = Apply[Union, sub[[2]]];
        {OpenerView[{structViewBuiltin[category, compTags, task], Column[sub[[1]]]}, 
        	ToExpression["Dynamic[$builtinStructState$"<>category<>"]"]], 
         compTags}
    ]

structViewBuiltin[ item:List[__List], tags_, task_String] :=
    Module[ {sub, compTags},
        sub = Transpose[Map[structViewBuiltin[#, tags, task] &, item]];
        compTags = Apply[Union, sub[[2]]];
        {Column[sub[[1]]], compTags}
    ]
    
structViewBuiltin[ {op_String, display_, _, _, _}, tags_, task_String] :=
    Module[ { },
        {Switch[ task,
            "prove",
            Row[{Checkbox[ Dynamic[ Theorema`Computation`Language`Private`buiActProve[op]]], Style[ DisplayForm[ display], "FormalTextInputFormula"]}, 
                Spacer[10]],
            "compute",
          	Row[{Checkbox[ Dynamic[ Theorema`Computation`Language`Private`buiActComputation[op]]], Style[ DisplayForm[ display], "FormalTextInputFormula"]}, 
          		Spacer[10]],
            "solve",
          	Row[{Checkbox[ Dynamic[ Theorema`Computation`Language`Private`buiActSolve[op]]], Style[ DisplayForm[ display], "FormalTextInputFormula"]}, 
          		Spacer[10]]
        ], {op}}
    ]

structViewBuiltin[ category_String, tags_, task_String] :=
    Module[ {},
    	Switch[ task,
    		"prove",
    		Row[{Checkbox[ Dynamic[ allTrue[ tags, Theorema`Computation`Language`Private`buiActProve], 
        		setAll[ tags, Theorema`Computation`Language`Private`buiActProve, #] &]], 
          		Style[ translate[category], "Section"]}, Spacer[10]],
    		"compute",
        	Row[{Checkbox[ Dynamic[ allTrue[ tags, Theorema`Computation`Language`Private`buiActComputation], 
        		setAll[ tags, Theorema`Computation`Language`Private`buiActComputation, #] &]], 
          		Style[ translate[category], "Section"]}, Spacer[10]],
          	"solve",
          	Row[{Checkbox[ Dynamic[ allTrue[ tags, Theorema`Computation`Language`Private`buiActSolve], 
        		setAll[ tags, Theorema`Computation`Language`Private`buiActSolve, #] &]], 
          		Style[ translate[category], "Section"]}, Spacer[10]]
    	]
    ]

structViewBuiltin[args___] :=
    unexpected[structViewBuiltin, {args}]

(* ::Subsubsection:: *)
(* structViewRules *)
Clear[structViewRules];

(* structured view for builtin operators
   follows the ideas of the structured view of the KB *)

structViewRules[ Hold[ rs_]] := structViewRules[ rs, {}][[1]]

structViewRules[{category_String, r__}, tags_] :=
    Module[ {sub, compTags},
        sub = Transpose[Map[structViewRules[#, tags] &, {r}]];
        compTags = Apply[Union, sub[[2]]];
        {OpenerView[{structViewRules[category, compTags], Column[sub[[1]]]}, 
        	ToExpression[StringReplace["Dynamic[NEWSYM]", 
        		"NEWSYM" -> "$ruleStructState$" <> ToString[ Hash[ category]]]]], 
         compTags}
    ]
  
structViewRules[ r_Symbol, tags_] :=
    Module[ { },
        {Row[{Checkbox[ Dynamic[ Theorema`Provers`Common`Private`ruleAct[ r]]], r}, 
                Spacer[10]], {r}}
    ]

structViewRules[ category_String, tags_] :=
    Module[ {},
    	Row[{Checkbox[ Dynamic[ allTrue[ tags, Theorema`Provers`Common`Private`ruleAct], 
        		setAll[ tags, Theorema`Provers`Common`Private`ruleAct, #] &]], 
          		Style[ translate[ category], "Section"]}, Spacer[10]]
    ]

structViewRules[args___] :=
    unexpected[structViewRules, {args}]


(* ::Subsubsection:: *)
(* check/set values *)

allTrue[ l_, test_] :=
    Catch[Module[ {},
              Scan[If[ Not[TrueQ[test[#]]],
                       Throw[False]
                   ] &, l];
              True
          ]]

setAll[l_, test_, val_] :=
    Scan[(test[#] = val) &, l]
   
(* ::Subsubsection:: *)
(* displayBuiltinBrowser *)

(* see displayKBBrowser *)

displayBuiltinBrowser[ task_String] :=
  Pane[ Column[{
  	Button[ translate[ "ResetBui"], initBuiltins[ {task}]],
  	structViewBuiltin[ $tmaBuiltins, {}, task][[1]]
  }],
  	ImageSizeAction -> "Scrollable", Scrollbars -> Automatic]
displayBuiltinBrowser[args___] := unexcpected[ displayBuiltinBrowser, {args}]

selectProver[ ] :=
    Pane[ Column[{
    	Row[ {Labeled[ PopupMenu[ Dynamic[ $selectedRuleSet], Map[ MapAt[ translate, #, {2}]&, $registeredRuleSets]], 
    		Style[ translate[ "pRules"], "CellLabel"], {{ Top, Left}}], Spacer[5],
    		Tooltip[ Graphics[{{RGBColor[0.485988, 0.555312, 1], Disk[{0, 0}, 1]}, Text[ "?", BaseStyle -> "Section"]}, ImageSize -> {20, 20}], 
    			Apply[ Function[ rs, MessageName[ rs, "usage"], {HoldFirst}], $selectedRuleSet]]}],
    	structViewRules[ $selectedRuleSet],
    	Row[ {Labeled[ PopupMenu[ Dynamic[ $selectedStrategy], Map[ MapAt[ translate, #, {2}]&, $registeredStrategies]], 
    		Style[ translate[ "pStrat"], "CellLabel"], {{ Top, Left}}], Spacer[5],
    		Tooltip[ Graphics[{{RGBColor[0.485988, 0.555312, 1], Disk[{0, 0}, 1]}, Text[ "?", BaseStyle -> "Section"]}, ImageSize -> {20, 20}], 
    			With[ {ss = $selectedStrategy}, MessageName[ ss, "usage"]]]}],
    	Labeled[ Dynamic[ Row[ {Slider[ Dynamic[ $selectedSearchDepth], {2, $maxSearchDepth, 1}],
    		InputField[ Dynamic[ $selectedSearchDepth], Number, FieldSize -> 3], 
    		Button[ "-", $selectedSearchDepth--],
    		Button[ "+", $selectedSearchDepth++],
    		Button[ "\[LeftSkeleton]", $maxSearchDepth/=2],
    		Button[ "\[RightSkeleton]", $maxSearchDepth*=2]}]], Style[ translate[ "sDepth"], "CellLabel"], {{ Top, Left}}],
    	Labeled[ RadioButtonBar[ 
    		Dynamic[Theorema`Provers`Common`Private`$proofCellStatus], {Open -> translate[ "open"], Closed -> translate[ "closed"]}], 
    		Style[ translate[ "proofCellStatus"], "CellLabel"], {{ Top, Left}}]	
    	}], {350, 450}, ImageSizeAction -> "Scrollable", Scrollbars -> Automatic]
selectProver[ args___] := unexpected[ selectRuleSet, {args}]

submitProveTask[ dummy_] := 
	Module[ {},
		Column[{
			Labeled[ displaySelectedGoal[ $selectedProofGoal], Style[ translate["selGoal"], "CellLabel"], {{ Top, Left}}],
			Labeled[ displaySelectedKB[], Style[ translate["selKB"], "CellLabel"], {{ Top, Left}}],
			(* Method -> "Queued" so that no time limit is set for proof to complete *)
			Button[ translate["prove"], execProveCall[ $selectedProofGoal, $selectedProofKB, $selectedRuleSet, $selectedStrategy, $selectedSearchDepth], Method -> "Queued"]
		}]
	]
submitProveTask[ args___] := unexpected[ submitProveTask, {args}]

execProveCall[ goal_, kb_, ruleSet_, strategy_, searchDepth_] :=
	Module[{nb = $proofInitNotebook, proof},
		$tcProveTab++;
		If[ NotebookFind[ nb, makeProofIDTag[ goal], All, CellTags] === $Failed,
			NotebookFind[ nb, goal[[1,1]], All, CellTags];
			NotebookFind[ nb, "CloseEnvironment", Next, CellStyle];
			SelectionMove[ nb, After, CellGroup],
			SelectionMove[ nb, All, CellGroup]
		];
		SetSelectedNotebook[ nb];
		NotebookWrite[ nb, Cell[ translate[ "Proof of"]<>" "<>goal[[3]]<>": \[Ellipsis]", "OpenProof", CellTags -> makeProofIDTag[ goal]]];

		proof = callProver[ ruleSet, strategy, goal, kb, searchDepth];
		printProveInfo[ goal, kb, ruleSet, strategy, proof, searchDepth];
	]
execProveCall[ args___] := unexpected[ execProveCall, {args}]

proofNavigation[ po_] :=
    Module[ {geom = {Max[ Count[ po, _ -> {__, Theorema`Provers`Common`Private`TERMINALNODE$|Theorema`Provers`Common`Private`PRFSIT$}]*20, 350], Max[ $selectedSearchDepth*15, 420]}},
        Pane[ Column[{
        	Pane[ showProofNavigation[ po, geom],
        		{350, 420}, ImageSizeAction -> "Scrollable", Scrollbars -> Automatic, ScrollPosition -> geom/2-{350,420}/2],
        	Button[ translate["abort"], Theorema`Provers`Common`Private`$proofAborted = True]
        }], {350, 450}]	
    ]
proofNavigation[ args___] := unexpected[ proofNavigation, {args}]

(* ::Subsubsection:: *)
(* printComputationInfo *)

(* this function is called during a computation (see processComputation[])
   effect: print a cell containg information about the environment settings for that computation *)
printComputationInfo[] :=
    Module[ {kbAct, bui, buiAct},
        kbAct = Cases[ $tmaEnv, {k_, _, l_} /; Theorema`Computation`Language`Private`activeComputationKB[k] -> l];
        bui = Cases[ DownValues[ Theorema`Computation`Language`Private`buiActComputation],
        	HoldPattern[ Verbatim[HoldPattern][ Theorema`Computation`Language`Private`buiActComputation[ op_String]] :> v_] -> {op, v}];
        buiAct = Cases[ bui, { op_, True} -> op];
        CellPrint[ Cell[ ToBoxes[ OpenerView[ {"", 
            Column[ {OpenerView[ {Style[ translate[ "KBcomp"], "CIContent"], Style[ kbAct, "CIContent"]}],
                OpenerView[ {Style[ translate[ "BuiComp"], "CIContent"], Style[ buiAct, "CIContent"]}],
                With[ {kb = Cases[ DownValues[ Theorema`Computation`Language`Private`activeComputationKB],
                	HoldPattern[ Verbatim[HoldPattern][ Theorema`Computation`Language`Private`activeComputationKB[ k_List]] :> v_] -> {k, v}],
                    allBui = bui},
                    Button[ Style[ translate["SetEnv"], "CellLabel"], setCompEnv[ kb, allBui], ImageSize -> Automatic]
                ]}
            ]}, False]], "ComputationInfo"]];
    ]
printComputationInfo[args___] := unexcpected[ printComputationInfo, {args}]

setCompEnv[ kb_List, bui_List] :=
	Module[{},
		Clear[Theorema`Computation`Language`Private`activeComputationKB];
		Theorema`Computation`Language`Private`activeComputationKB[_] := False;
		Scan[(Theorema`Computation`Language`Private`activeComputationKB[#[[1]]] = #[[2]])&, kb];
		Scan[(Theorema`Computation`Language`Private`buiActComputation[#[[1]]] = #[[2]])&, bui]
	]
setCompEnv[ args___] := unexpected[ setCompEnv, {args}]


(* ::Subsubsection:: *)
(* printProofInfo *)

printProveInfo[ goal_, kb_, rules_, strategy_, { pVal_, proofObj_}, searchDepth_] :=
    Module[ {kbAct, bui, buiAct},
        kbAct = Map[ Part[ #, 3]&, kb];
        bui = Cases[ DownValues[ Theorema`Computation`Language`Private`buiActProve],
        	HoldPattern[ Verbatim[HoldPattern][ Theorema`Computation`Language`Private`buiActProve[ op_String]] :> v_] -> {op, v}];
        buiAct = Cases[ bui, { op_, True} -> op];
        NotebookFind[ $proofInitNotebook, makeProofIDTag[ goal], All, CellTags];
        NotebookWrite[ $proofInitNotebook, Cell[ translate[ "Proof of"]<>" "<>goal[[3]]<>": "<>ToString[pVal], "OpenProof", CellTags -> makeProofIDTag[ goal]]];
        (* Use Method -> "Queued" so that no time limit for proof display applies *)
        NotebookWrite[ $proofInitNotebook, Cell[ BoxData[ ToBoxes[
        	Button[ translate["ShowProof"], displayProof[ proofObj], ImageSize -> Automatic, Method -> "Queued"]]], "ProofDisplay"]];
        NotebookWrite[ $proofInitNotebook, Cell[ ToBoxes[
        	OpenerView[ {Spacer[10], 
            Column[ {OpenerView[ {Style[ translate[ "GoalProve"], "PIContent"], Style[ goal[[3]], "PIContent"]}],
            	OpenerView[ {Style[ translate[ "KBprove"], "PIContent"], Style[ kbAct, "PIContent"]}],
                OpenerView[ {Style[ translate[ "BuiProve"], "PIContent"], Style[ buiAct, "PIContent"]}],
                OpenerView[ {Style[ translate[ "selProver"], "PIContent"], Style[ {rules, strategy}, "PIContent"]}],
                With[ {allKB = Cases[ DownValues[ kbSelectProve],
                	HoldPattern[ Verbatim[HoldPattern][ kbSelectProve[ k_List]] :> v_] -> {k, v}],
                    allBui = bui, allRules = Cases[ DownValues[ Theorema`Provers`Common`Private`ruleAct],
                	HoldPattern[ Verbatim[HoldPattern][ Theorema`Provers`Common`Private`ruleAct[ r_Symbol]] :> v_] -> {r, v}]},
                    Button[ translate["SetEnv"], setProveEnv[ goal, allKB, allBui, rules, strategy, allRules, searchDepth], ImageSize -> Automatic]
                ]}
            ]}, False]], "ProofInfo"]];
        NotebookWrite[ $proofInitNotebook, Cell[ "\[EmptySquare]", "CloseProof"]];
    ]
printProveInfo[args___] := unexcpected[ printProveInfo, {args}]

setProveEnv[ goal_, kb_List, bui_List, ruleSet_, strategy_, allRules_List, searchDepth_] :=
	Module[{},
		$selectedProofGoal = goal;
		NotebookLocate[ goal[[1,1]]];
		Clear[kbSelectProve];
		kbSelectProve[_] := False;
		Scan[(kbSelectProve[#[[1]]] = #[[2]])&, kb];
		Clear[Theorema`Provers`Common`Private`ruleAct];
		Theorema`Provers`Common`Private`ruleAct[_] := True;
		Scan[(Theorema`Provers`Common`Private`ruleAct[#[[1]]] = #[[2]])&, allRules];
		Scan[(Theorema`Computation`Language`Private`buiActProve[#[[1]]] = #[[2]])&, bui];
		$selectedRuleSet = ruleSet;
		$selectedStrategy = strategy;
		$selectedSearchDepth = searchDepth;
	]
setProveEnv[ args___] := unexpected[ setProveEnv, {args}]

makeProofIDTag[ { id_, _,_}] := Apply[ StringJoin, Riffle[ Prepend[ id, "Proof"], "|"]]
makeProofIDTag[ args___] := unexpected[ makeProofIDTag, {args}]


(* ::Section:: *)
(* Palettes *)

insertNewEnv[type_String] :=
    Module[ {nb = InputNotebook[]},
        NotebookWrite[
         nb, {newOpenEnvCell[ type], 
          newFormulaCell[ type],
          newEndEnvCell[],
          newCloseEnvCell[]}];
    ]
insertNewEnv[args___] :=
    unexpected[insertNewEnv, {args}]

openNewEnv[type_String] :=
    Module[ {},
        NotebookWrite[ InputNotebook[], newOpenEnvCell[ type]];
    ]
openNewEnv[args___] :=
    unexpected[openNewEnv, {args}]

insertNewFormulaCell[ style_String] := 
	Module[{}, 
		NotebookWrite[ InputNotebook[], newFormulaCell[ style]];
		(* we use NotebookFind because parameter Placeholder in NotebookWrite does not work (Mma 8.0.1) *)
		NotebookFind[ InputNotebook[], "\[SelectionPlaceholder]", Previous];
	]
insertNewFormulaCell[args___] :=
    unexpected[insertNewFormulaCell, {args}]

closeEnv[] :=
    Module[ {},
        NotebookWrite[ InputNotebook[], {newEndEnvCell[], newCloseEnvCell[]}];
    ]
closeEnv[args___] :=
    unexpected[closeEnv, {args}]

newFormulaCell[ "COMPUTE"] = Cell[BoxData["\[SelectionPlaceholder]"], "Computation"]	
newFormulaCell[ style_, label_:$initLabel] = Cell[BoxData["\[SelectionPlaceholder]"], "FormalTextInputFormula", CellTags->{label}]	
newFormulaCell[args___] :=
    unexpected[newFormulaCell, {args}]

newOpenEnvCell[ type_String] := Cell[ type, "OpenEnvironment"]
newOpenEnvCell[args___] :=
    unexpected[newOpenEnvCell, {args}]

newEndEnvCell[] := Cell[ "\[GraySquare]", "EndEnvironmentMarker"]
newEndEnvCell[args___] :=
    unexpected[newEndEnvCell, {args}]

newCloseEnvCell[] := Cell[ "", "CloseEnvironment"]
newCloseEnvCell[args___] :=
    unexpected[newCloseEnvCell, {args}]


(* ::Subsection:: *)
(* Buttons *)

envButtonData["DEF"] := "tcLangTabEnvTabButtonDefLabel";
envButtonData["THM"] := "tcLangTabEnvTabButtonThmLabel";
envButtonData["LMA"] := "tcLangTabEnvTabButtonLmaLabel";
envButtonData["PRP"] := "tcLangTabEnvTabButtonPrpLabel";
envButtonData["COR"] := "tcLangTabEnvTabButtonCorLabel";
envButtonData["CNJ"] := "tcLangTabEnvTabButtonCnjLabel";
envButtonData["ALG"] := "tcLangTabEnvTabButtonAlgLabel";
envButtonData["EXM"] := "tcLangTabEnvTabButtonExmLabel";
envButtonData[args___] :=
    unexpected[envButtonData, {args}]

makeEnvButton[ bname_String] :=
    With[ { bd = envButtonData[bname]},
			Button[ translate[bd], insertNewEnv[ translate[bd]], Alignment -> {Left, Top}]
    ]
makeEnvButton[args___] :=
    unexpected[makeEnvButton, {args}]

makeFormButton[] :=
    Button[ translate["tcLangTabEnvTabButtonFormLabel"], insertNewFormulaCell[ "Env"], Alignment -> {Left, Top}]
makeFormButton[args___] :=
    unexpected[makeFormButton, {args}]
    
allEnvironments = {"DEF", "THM", "LMA", "PRP", "COR", "CNJ", "ALG", "EXM"};

envButtons[] :=
    Pane[ 
    Column[{
    Grid[ Partition[ Map[ makeEnvButton, allEnvironments], 2]],
    Grid[ {{makeFormButton[]}}]
    }, Center, Dividers->Center]]
envButtons[args___] :=
    unexpected[envButtons, {args}]

(* ::Section:: *)
(* Archives Tab *)

archButtons[] :=
    Module[ {},
        Pane[
        	Column[{
        		OpenerView[{Style[translate["tcLangTabArchTabSectionCreate"],"Section"], Column[{
        		makeArchCreateButton[],
        		makeArchNewButton[],
        		makeArchInfoButton[],
        		makeArchCloseButton[]}]}],
        		OpenerView[{Style[translate["tcLangTabArchTabSectionLoad"],"Section"], Column[{
        		makeArchLoadButton[]}]}]}
        	]
        ]
    ]
archButtons[args___] := unexpected[archButtons, {args}]

makeArchCreateButton[] :=
	Button[ translate["tcLangTabArchTabButtonNewLabel"], insertNewArchive[ NotebookCreate[ StyleDefinitions -> FileNameJoin[{ "Theorema", "TheoremaNotebook.nb"}]]], Alignment -> {Left, Top}, Method -> "Queued"]
makeArchNewButton[args___] := unexpected[makeArchNewButton, {args}]

makeArchNewButton[] :=
	Button[ translate["tcLangTabArchTabButtonMakeLabel"], insertNewArchive[ InputNotebook[]], Alignment -> {Left, Top}, Method -> "Queued"]
makeArchNewButton[args___] := unexpected[makeArchNewButton, {args}]

makeArchInfoButton[] :=
	Button[ translate["tcLangTabArchTabButtonInfoLabel"], insertArchiveInfo[], Alignment -> {Left, Top}]
makeArchInfoButton[args___] := unexpected[makeArchInfoButton, {args}]

makeArchCloseButton[] :=
	Button[ translate["tcLangTabArchTabButtonCloseLabel"], insertCloseArchive[], Alignment -> {Left, Top}]
makeArchCloseButton[args___] := unexpected[makeArchCloseButton, {args}]

insertNewArchive[ nb_NotebookObject] :=
	Module[{},
		SelectionMove[nb, Before, Notebook];
		NotebookWrite[nb, archiveOpenCell[]];
		insertArchiveInfo[];
		If[ NotebookFind[nb, "CloseArchive", All, CellStyle] === $Failed,
			SelectionMove[nb, After, Notebook];
			insertCloseArchive[];
		];
		NotebookFind[nb, "OpenArchive", All, CellStyle]
	]
insertNewArchive[args___] := unexpected[insertNewArchive, {args}]

insertArchiveInfo[] := NotebookWrite[ InputNotebook[], archiveInfoCells[]]
insertArchiveInfo[args___] := unexpected[insertArchiveInfo, {args}]

insertCloseArchive[] := NotebookWrite[ InputNotebook[], archiveCloseCells[]]
insertCloseArchive[args___] := unexpected[insertCloseArchive, {args}]

archiveOpenCell[] := 
	Module[ {name, input=""},
		name = DialogInput[ 
			Column[{ 
				translate["archiveNameDialogField"],
				InputField[ Dynamic[ input], String, FieldHint -> translate["archiveNameDialogHint"]],
				ChoiceButtons[ {DialogReturn[ input], DialogReturn[ ""]}]}]];
		If[ name === "" || StringTake[ name, -1] =!= "`",
			name = name <> "`"
		]; 
		Cell[ BoxData["\"\<" <> name <> "\>\""], "OpenArchive", CellFrameLabels->{{translate["archLabelName"], None}, {None, translate["archLabelBegin"]}}]
	]
archiveOpenCell[args___] := unexpected[archiveOpenCell, {args}]

archiveInfoCells[] := {
	Cell[ BoxData[RowBox[{"{","}"}]], "ArchiveInfo", CellFrameLabels->{{translate["archLabelNeeds"], None}, {None, None}}],
	Cell[ BoxData[RowBox[{"{","}"}]], "ArchiveInfo", CellFrameLabels->{{translate["archLabelPublic"], None}, {None, None}}]}
archiveInfoCells[args___] := unexpected[archiveInfoCells, {args}]

archiveCloseCells[] := Cell["\[FilledUpTriangle]", "CloseArchive", CellFrameLabels->{{None, None}, {translate["archLabelEnd"], None}}]
archiveCloseCells[args___] := unexpected[archiveCloseCells, {args}]

makeArchLoadButton[] :=
    DynamicModule[ {arch = $TheoremaArchiveDirectory},
        Column[{
            Dynamic[showSelectedArchives[arch]], 
            Row[{FileNameSetter[Dynamic[arch], "OpenList", {translate["fileTypeArchive"]->{"*.ta"}}, Appearance -> translate["tcLangTabArchTabButtonSelectLabel"]],
            Button[ translate["tcLangTabArchTabButtonLoadLabel"], (loadArchive[arch];arch=$TheoremaArchiveDirectory;), Alignment -> {Left, Top}]}]}]
    ]
makeArchLoadButton[args___] := unexpected[makeArchLoadButton, {args}]

showSelectedArchives[ l_List] :=
    Pane[ Column[ Map[ Style[ archiveName[ #, Short], LineBreakWithin -> False]&, l]], ImageSize -> {200,20*Length[l]}, Scrollbars -> Automatic]
showSelectedArchives[ s_String] :=
    translate["tcLangTabArchTabNoArchSel"]
showSelectedArchives[args___] := unexpected[showSelectedArchives, {args}]

(* ::Section:: *)
(* Math Tab *)

$buttonNat = False;

langButtonData["AND1"] := 
	{
		If[ $buttonNat, 
			translate["AND1"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[Wedge]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[Wedge]", "\[Placeholder]"}],
		translate["CONN2STRONGTooltip"]
	}

langButtonData["AND2"] := 
	{
		If[ $buttonNat, 
			translate["AND2"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[And]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[And]", "\[Placeholder]"}],
		translate["CONN2WEAKTooltip"]
	}

langButtonData["OR1"] := 
	{
		If[ $buttonNat, 
			translate["OR1"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[Vee]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[Vee]", "\[Placeholder]"}],
		translate["CONN2STRONGTooltip"]
	}

langButtonData["OR2"] := 
	{
		If[ $buttonNat, 
			translate["OR2"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[Or]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[Or]", "\[Placeholder]"}],
		translate["CONN2WEAKTooltip"]
	}

langButtonData["IMPL1"] := 
	{
		If[ $buttonNat, 
			translate["IMPL1"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[DoubleLongRightArrow]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]",
			TagBox[ "\[DoubleLongRightArrow]", Identity, SyntaxForm->"a\[DoubleRightArrow]b"], "\[Placeholder]"}],
		translate["CONN2STRONGTooltip"]
	}

langButtonData["IMPL2"] := 
	{
		If[ $buttonNat, 
			translate["IMPL2"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[Implies]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[Implies]", "\[Placeholder]"}],
		translate["CONN2WEAKTooltip"]
	}

langButtonData["EQUIV1"] := 
	{
		If[ $buttonNat, 
			translate["EQUIV1"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[DoubleLongLeftRightArrow]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]",
			TagBox[ "\[DoubleLongLeftRightArrow]", Identity, SyntaxForm->"a\[DoubleRightArrow]b"], "\[Placeholder]"}],
		translate["CONN2STRONGTooltip"]
	}

langButtonData["EQUIV2"] := 
	{
		If[ $buttonNat, 
			translate["EQUIV2"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[DoubleLeftRightArrow]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]",
			TagBox[ "\[DoubleLeftRightArrow]", Identity, SyntaxForm->"a\[Implies]b"], "\[Placeholder]"}],
		translate["CONN2WEAKTooltip"]
	}

langButtonData["EQ1"] := 
	{
		If[ $buttonNat, 
			translate["EQ1"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"\[Equal]",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", "\[Equal]", "\[Placeholder]"}],
		translate["CONN2Tooltip"]
	}

langButtonData["EQ2"] := 
	{
		If[ $buttonNat, 
			translate["EQ2"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				"=",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]",
			TagBox[ "=", Identity, SyntaxForm->"a\[Equal]b"], "\[Placeholder]"}],
		translate["CONN2Tooltip"]
	}

langButtonData["EQUIVDEF"] := 
	{
		If[ $buttonNat, 
			translate["EQUIVDEF"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				RowBox[{":", "\[NegativeThickSpace]\[NegativeThinSpace]", "\[DoubleLongLeftRightArrow]"}],
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]",
			TagBox[ RowBox[{":", "\[NegativeThickSpace]\[NegativeThinSpace]", "\[DoubleLongLeftRightArrow]"}], Identity, SyntaxForm->"a\[Implies]b"], "\[Placeholder]"}],
		translate["EQUIVDEFTooltip"]
	}

langButtonData["EQDEF"] := 
	{
		If[ $buttonNat, 
			translate["EQDEF"], 
			DisplayForm[RowBox[{TagBox[ FrameBox["left"], "SelectionPlaceholder"],
				":=",
				TagBox[ FrameBox["right"], "SelectionPlaceholder"]}]]],
		RowBox[{"\[SelectionPlaceholder]", ":=", "\[Placeholder]"}],
		translate["EQDEFTooltip"]
	}

langButtonData["FORALL1"] := 
	{
		If[ $buttonNat, 
			translate["FORALL1"], 
			DisplayForm[RowBox[{UnderscriptBox["\[ForAll]", Placeholder["rg"]], TagBox[ FrameBox["expr"], "SelectionPlaceholder"]}]]],
		RowBox[{UnderscriptBox["\[ForAll]", "\[Placeholder]"], "\[SelectionPlaceholder]"}],
		translate["QUANT1Tooltip"]
	}

langButtonData["FORALL2"] := 
	{
		If[ $buttonNat, 
			translate["FORALL2"], 
			DisplayForm[RowBox[{UnderscriptBox[ UnderscriptBox["\[ForAll]", Placeholder["rg"]], Placeholder["cond"]], TagBox[ FrameBox["expr"], "SelectionPlaceholder"]}]]],
		RowBox[{UnderscriptBox[ UnderscriptBox["\[ForAll]", "\[Placeholder]"], "\[Placeholder]"], "\[SelectionPlaceholder]"}],
		translate["QUANT2Tooltip"]
	}

langButtonData["EXISTS1"] := 
	{
		If[ $buttonNat, 
			translate["EXISTS1"], 
			DisplayForm[RowBox[{UnderscriptBox["\[Exists]", Placeholder["rg"]], TagBox[ FrameBox["expr"], "SelectionPlaceholder"]}]]],
		RowBox[{UnderscriptBox["\[Exists]", "\[Placeholder]"], "\[SelectionPlaceholder]"}],
		translate["QUANT1Tooltip"]
	}

langButtonData["EXISTS2"] := 
	{
		If[ $buttonNat, 
			translate["EXISTS2"], 
			DisplayForm[RowBox[{UnderscriptBox[ UnderscriptBox["\[Exists]", Placeholder["rg"]], Placeholder["cond"]], TagBox[ FrameBox["expr"], "SelectionPlaceholder"]}]]],
		RowBox[{UnderscriptBox[ UnderscriptBox["\[Exists]", "\[Placeholder]"], "\[Placeholder]"], "\[SelectionPlaceholder]"}],
		translate["QUANT2Tooltip"]
	}
langButtonData[args___] :=
    unexpected[langButtonData, {args}]

makeLangButton[ bname_String] :=
    With[ { bd = langButtonData[bname]},
			Tooltip[ Button[ bd[[1]], 
				FrontEndExecute[{NotebookApply[ InputNotebook[], bd[[2]], Placeholder]}], Appearance -> "DialogBox", Alignment -> {Left, Top}, ImageSize -> All],
				bd[[3]], TooltipDelay -> 0.5]
    ]
makeLangButton[args___] :=
    unexpected[makeLangButton, {args}]

allFormulae = {{"Sets", {}},
			   {"Arithmetic", {}},
			   {"Logic", {"AND1", "AND2", "OR1", "OR2", "IMPL1", "IMPL2", "EQUIV1", "EQUIV2", "EQ1", "EQ2", "EQUIVDEF", "EQDEF", "FORALL1", "FORALL2", "EXISTS1", "EXISTS2"}}
};

makeButtonCategory[ {category_String, buttons_List}] :=
	OpenerView[{
			Style[ translate[ category], "Section"],
			Grid[ Partition[ Map[ makeLangButton, buttons], 2], Alignment -> {Left, Top}]}]
makeButtonCategory[ args___] := unexpected[ makeButtonCategory, {args}]

langButtons[] := Pane[ 
	Column[{
		Column[ Map[ makeButtonCategory, allFormulae]],
		Row[{translate["tcLangTabMathTabBS"], 
			Row[{RadioButton[Dynamic[$buttonNat], False], translate["tcLangTabMathTabBSform"]}, Spacer[2]], 
			Row[{RadioButton[Dynamic[$buttonNat], True], translate["tcLangTabMathTabBSnat"]}, Spacer[2]]}, Spacer[10]]
	}, Dividers -> Center, Spacings -> 2]]
langButtons[args___] :=
    unexpected[langButtons, {args}]
    
compSetup[] := Pane[ 
	Column[{
		makeCompButton[]
	}, Dividers -> Center, Spacings -> 4]]
compSetup[args___] :=
    unexpected[compSetup, {args}]

makeCompButton[] :=
    Button[ translate["tcComputeTabSetupTabButtonCompLabel"], insertNewFormulaCell[ "COMPUTE"], Alignment -> {Left, Top}]
makeCompButton[args___] :=
    unexpected[makeCompButton, {args}]


(* ::Section:: *)
(* end of package *)

initGUI[];

End[]; (* End Private Context *)

EndPackage[];
