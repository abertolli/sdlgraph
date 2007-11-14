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

{------------------------------------------------------------------}
procedure testMode(GD,GM:integer);

begin
   initgraph(GD,GM,'');

   { Just display some blocks of color here. }

end;
{------------------------------------------------------------------}

Begin

testMode(D4bit,m640x480);

End.

