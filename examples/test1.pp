Uses SdlGraph_Crt, SdlGraph;

Var GM,GD:Integer;
Begin
  GD:=D32bit;
  GM:=m1024x768;
  SDLgraph_SetWindowed(true);
  InitGraph(GD, GM, '');
  Repeat until keypressed;
  CloseGraph;
End.