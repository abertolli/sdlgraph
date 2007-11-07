Uses SDL,SDL_types, SDL_video, SDL_timer, SdlGraph_Crt;

Const Width=5;
Const Height=5;
Const Sneshinok=55; {Count of falling snowflakes}
Const MaxSpeed=10;

Type PUint8 =  ^Uint8;
     PUint16 = ^Uint16;
     PUint32 = ^Uint32;

procedure PutPixel(surf:PSDL_Surface; X,Y: Integer; color: Uint32);
  Var p:PUint8;
      bpp:Uint8;
  Begin
    if(X<0) or (X>=surf^.w) or (Y<0) or (Y>=surf^.h) then
      Exit;
    bpp:=surf^.format^.BytesPerPixel;
    p:= PUint8(surf^.pixels) + Y * surf^.pitch + X * bpp;
    Case bpp of
      2: PUint16(p)^:=color;
      4: PUint32(p)^:=color;
      else
        Writeln('PutPixel_NoLock: Unknown bpp: ', bpp);
      End;
  End;

Var screen,snowflake:PSDL_Surface;
    sneg:Array[1..Sneshinok] of Record
                                D,X,Y,V:Integer;
                                End;
    i:Integer;
    dw:Uint32;
Begin
  SDL_Init(SDL_INIT_VIDEO);
  screen:=SDL_SetVideoMode(1024, 768, 32, SDL_HWSURFACE);

  for i:=1 to Sneshinok do
    sneg[i].y:=screen^.h;
  Repeat
  for i:=1 to Sneshinok do
    if(sneg[i].y>=screen^.h) then
    Begin
    sneg[i].x:=Random(screen^.w-Width);
    sneg[i].y:=0;
    sneg[i].v:=Random(MaxSpeed)+1;
    sneg[i].d:=Random(2)-1;
    End
    else
    with sneg[i] do
      Begin
      y:=y+v;
      dw:=SDL_GetTicks;
      PutPixel(screen, x,y, SDL_MapRGB(screen^.format, 255,255,255));
      Writeln('Time Pixel Draws: ', SDL_GetTicks-dw);
      End;
    SDL_Flip(screen);
    Delay(10);
    SDL_FillRect(screen, Nil, SDL_MapRGB(screen^.format, 0,0,0));
  until keypressed;
  SDL_Quit;
End.