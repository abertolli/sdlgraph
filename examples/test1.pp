Uses SdlGraph_Crt, SdlGraph;

Var GM,GD:Integer;
    W,H:Integer;
Begin
  randomize;
  GD:=Detect;
  {GM:=m1024x768;}
  {SDLgraph_SetWindowed(true);}
  InitGraph(GD, GM, '');
  W:=GetMaxX;
  H:=GetMaxY;
  Repeat
    PutPixel(random(W), random(H), random($FF), random($FF), random($FF));
  until keypressed;
  CloseGraph;
End.