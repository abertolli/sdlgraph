Uses SdlGraph,SdlGraph_Crt;

{$MODE OBJFPC}

Var W, H, Gm,GD:Integer;
Begin
GD:=Detect;
InitGraph(GD, GM, 'e:\bp7\bgi');
W:=GetMaxX;
H:=GetMaxY;
SetFillStyle(WideDotFill, LightBlue);
Bar3D(W div 2 - 10, H div 2 - 10, W div 2 +10,  H div 2 + 10, 50, true);

Repeat until keypressed;
CloseGraph;
End.