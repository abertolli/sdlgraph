Uses SdlGraph, SdlGraph_Crt;

Const Tab=20;

Var W,H,GM, GD:Integer;
Begin
  GD:=D32bit;
  GM:=m320x256;
  InitGraph(GD, GM);
  W:=GetMaxX;
  H:=GetMaxY;

  Rectangle(W div 2 -Tab, H div 2 -3*Tab, W div 2 + Tab, H div 2 + 3*Tab);
  SetColor(Red);
  SetFillStyle(CloseDotFill, Red);
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