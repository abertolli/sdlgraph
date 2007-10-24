Uses Crt, SdlGraph;

Var GM,GD:Integer;
Begin
  GD:=Detect;
  GM:=sdlgraph_windowed;{Will hang system on non-windowed mode}
  InitGraph(GD, GM, '');
  Repeat until keypressed; 
  CloseGraph;
End.