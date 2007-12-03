Uses SdlGraph, SdlGraph_Crt;

Const Tab=20;

Var W,H,GM, GD:Integer;
Begin
  SDLgraph_SetWindowed(true);
  GD:=D32bit;
  GM:=m320x256;
  InitGraph(GD, GM);
  W:=GetMaxX;
  H:=GetMaxY;
  //We don't have enough functions, to write this example
  Rectangle(W div 2 -Tab, H div 2 -3*Tab, W div 2 + Tab, H div 2 + 3*Tab);
  SetColor(Red);
  SetFillStyle(LineFill, Red);
  Circle(W div 2, H div 2 - 2*Tab, Round(Tab*0.9));
  FloodFill(W div 2, H div 2 - 2*Tab, Red);

  SetColor(Yellow);
  SetFillStyle(SolidFill, Yellow);
  Circle(W div 2, H div 2, Round(Tab*0.9));
  FloodFill(W div 2, H div 2, Yellow);

  SetColor(Green);
  SetFillStyle(SolidFill, Green);
  Circle(W div 2, H div 2 + 2*Tab, Round(Tab*0.9));
  FloodFill(W div 2, H div 2 + 2*Tab, Green);
  Repeat until keypressed;
  CloseGraph;
End.