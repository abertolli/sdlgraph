Program SDLGraph_Test;
{
Copyright (C) 2007 - Angelo Bertolli
This program tries to test color display in various modes for SDLGraph.
Turn this into a generic test for SDLGraph.

Demo: compile and run for demonstration

}

Uses sdlgraph_crt, sdlgraph;

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

