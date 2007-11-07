Uses SdlGraph_Crt, SdlGraph;

Const Width=10;
Const Height=10;
Const Sneshinok=55; {Count of falling snowflakes}
Const MaxSpeed=5;
Var i,GM, GD, W,H:Integer;
    bmp:Pointer;
    sneg:Array[1..Sneshinok] of Record
                                D,X,Y,V:Integer;
                                End;
Begin
Randomize;
GD:=D32bit;
GM:=m640x480;
InitGraph(GD,GM,'E:\BP7\BGI');
W:=GetMaxX;
H:=GetMaxY;
Line(Width div 2, 0, Width div 2, Height);
Line(0, Height div 2, Width, Height div 2);
Line(Round(Width/2*(1-1/sqrt(2))), Round(Height/2*(1-1/sqrt(2))),
     Round(Width/2*(1+1/sqrt(2))), Round(Height/2*(1+1/sqrt(2))));
Line(Round(Width/2*(1+1/sqrt(2))), Round(Height/2*(1-1/sqrt(2))),
     Round(Width/2*(1-1/sqrt(2))), Round(Height/2*(1+1/sqrt(2))));

GetMem(bmp,ImageSize(0,0,Width, Height));
GetImage(0,0, Width, Height, bmp^);

ClearDevice;
for i:=1 to Sneshinok do
 sneg[i].y:=H;
Repeat
 for i:=1 to Sneshinok do
  if(sneg[i].y>=H) then
   Begin
   sneg[i].x:=Random(W-Width);
   sneg[i].y:=0;
   sneg[i].v:=Random(MaxSpeed)+1;
   sneg[i].d:=Random(2)-1;
   End
  else
   with sneg[i] do
    Begin
    y:=y+v;
    PutImage(x+D*Round(30*sin(y/100)), y, bmp^, 0);
    End;
 Delay(10);
 ClearDevice;
until keypressed;
CloseGraph;
End.
