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
    PutPixel(random(W), random(H), SDLgraph_color(random($FFFFFF)));
    Delay(100);
  until keypressed;
  CloseGraph;
End.