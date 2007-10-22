Uses Crt, SdlGraph;

Var GM,GD:Integer;
Begin
  GD:=Detect;
  GM:=1;
  InitGraph(GD, GM, '');
  Repeat until keypressed;
  CloseGraph;
End.