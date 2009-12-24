Program GraphCompatibility;
{
Copyright (C) 2007 - Angelo Bertolli

This program should compile on FPC and TP 5.5 or later, and should
provide identical results.

}

{$IFDEF FPC}
Uses SdlGraph_Crt, SdlGraph;
{$ELSE}
Uses crt, graph;
{$ENDIF}

Var

   GD, GM: integer;

Begin

   initgraph(GD,GM,'');
   { Test setting colors }
   { Test drawing primitives }
   { Test getting colors }


End.

