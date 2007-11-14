Uses SdlGraph_Crt, SdlGraph;

Const Tab=20;
Const Numbers=10;
Var mas:Array[1..Numbers] of Real;
    Xl, Yl, Y,X,Pitch, OsY, GM, GD, W, H, i:Integer;
    k, Max, Min:Real;
    S:String;
Begin
{
I don't know. I works ok for me. Try to use something, instead of Detect.
>Why doesn't it work with windowed mode?
>DetectGraph: SDL_ListModes returned: 4294967295
>An unhandled exception occurred at $00000000 :
>EAccessViolation : Access violation
}
SDLgraph_SetWindowed(false);
Writeln('Enter ',Numbers,' real numbers');
for i:=1 to Numbers do
 Begin
 Read(mas[i]);
 if(i=1) then
  Begin
  Max:=mas[1];
  Min:=mas[1];
  End
 else
  Begin
  if(Max<mas[i]) then
   Max:=mas[i];
  if(Min>mas[i]) then
   Min:=mas[i];
  End;
 End;

GD:=Detect;
InitGraph(GD,GM,'H:\BGI');
W:=GetMaxX;
H:=GetMaxY;
Line(Tab, 0, Tab, H);
Line(Tab, 0, Tab-5, 5);
Line(Tab, 0, Tab+5, 5);
if(Min>=0) then
 Begin
 OsY:= H-Tab;
 k:=(H-2*Tab)/Max;
 End
else if(Max<=0) then
 Begin
 OsY:= Tab;
 k:=-(H-Tab)/Min;
 End
else
 Begin
 OsY:= H div 2;
 if(Abs(Min)>Max) then
  k:=(OsY-Tab)/Abs(Min)
 else
  k:=(OsY-Tab)/Max;
 End;
Line(0, OsY, W, OsY);
Line(W, OsY, W-5, OsY-5);
Line(W, OsY, W-5, OsY+5);
Pitch:=(W-Tab) div Numbers;
SetFillStyle(SolidFill, Brown);
for i:=1 to Numbers do
 Begin
 SetColor(Green);
 X:=2*Tab + Pitch*(i-1);
 Y:=OsY-Round(k*mas[i]);
 Circle(X,Y, 5);
 FloodFill(X,Y, Green);
 if(i=1) then
  Begin
  Xl:=X;
  Yl:=Y;
  End
 else
  Line(Xl, Yl, X,Y);
 SetColor(i);
 Str(mas[i]:0:2, s);
 OutTextXY(X+2, OsY+2, s);
 Str(i, s);
 OutTextXY(X-5-TextWidth(s), Y-5-TextHeight(s), s);
 Xl:=X;
 Yl:=Y;
 End;
SetColor(Red);
OutTextXY(Tab+2, OsY+2, '0');
Repeat until keypressed;
CloseGraph;
End.
