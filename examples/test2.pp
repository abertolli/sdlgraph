Uses SdlGraph_Crt, SdlGraph;

Var GM,GD:Integer;
    W,H:Integer;
Begin
  randomize;
  GD:=D32bit;
  GM:=m1024x768;
  SDLgraph_SetWindowed(true);
  InitGraph(GD, GM, '');
  W:=GetMaxX;
  H:=GetMaxY;
  Repeat
    SetColor(SDLgraph_MakeColor(random($FF), random($FF), random($FF)));
    Line(random(W), random(H), random(W), random(H));
  until keypressed;
  CloseGraph;
End.