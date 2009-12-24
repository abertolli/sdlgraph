Uses SdlGraph_Crt, SdlGraph;

Var GM,GD:Integer;
    W,H:Integer;
Begin
  {SDLgraph_SetWindowed(true);}
  randomize;
  GD:=Detect;
  InitGraph(GD, GM, '');
  W:=GetMaxX;
  H:=GetMaxY;
  Repeat
    SetColor(random($FF), random($FF), random($FF));
    Line(random(W), random(H), random(W), random(H));
  until keypressed;
  CloseGraph;
End.