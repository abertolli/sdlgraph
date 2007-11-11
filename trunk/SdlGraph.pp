{This code is covered under the terms of the LGPL.}

UNIT SDLGraph;

{$inline on}

INTERFACE

Uses SDL_types;
{ Public things and function prototypes }

Const

   SDLGraph_version = '0.1';


{ Constants for mode selection }

   Detect = 0;
   D1bit = 11;
   D2bit = 12;
   D4bit = 13;
   D6bit = 14;  { 64 colors Half-brite mode - Amiga }
   D8bit = 15;
   D12bit = 16; { 4096 color modes HAM mode - Amiga }
   D15bit = 17;
   D16bit = 18;
   D24bit = 19; { not yet supported }
   D32bit = 20; { not yet supported }
   D64bit = 21; { not yet supported }

   lowNewDriver = 11;
   highNewDriver = 21;

   detectMode = 30000;
   m320x200 = 30001;
   m320x256 = 30002; { amiga resolution (PAL) }
   m320x400 = 30003; { amiga/atari resolution }
   m512x384 = 30004; { mac resolution }
   m640x200 = 30005; { vga resolution }
   m640x256 = 30006; { amiga resolution (PAL) }
   m640x350 = 30007; { vga resolution }
   m640x400 = 30008;
   m640x480 = 30009;
   m800x600 = 30010;
   m832x624 = 30011; { mac resolution }
   m1024x768 = 30012;
   m1280x1024 = 30013;
   m1600x1200 = 30014;
   m2048x1536 = 30015;

   lowNewMode = 30001;
   highNewMode = 30015;

{PutImage constants: not used}
   NormalPut=0;
   XORPut   =0;


{Constants for default (EGA) colors}
   black          = 0;
   blue           = 1;
   green          = 2;
   cyan           = 3;
   red            = 4;
   magenta        = 5;
   brown          = 6;
   lightgray      = 7;
   darkgray       = 8;
   lightblue      = 9;
   lightgreen     = 10;
   lightcyan      = 11;
   lightred       = 12;
   lightmagenta   = 13;
   yellow         = 14;
   white          = 15;

{Fill function constants}
   EmptyFill=0;
   SolidFill=1;
   LineFill=2;
   LtSlashFill=3;
   SlashFill=4;
   BkSlashFill=5;
   LtBkSlashFill=6;
   HatchFill=7;
   XHatchFill=8;
   InterLeaveFill=9;
   WideDotFill=10;
   CloseDotFill=11;
   UserFill=12;


Type

  {We should move this type to the Implementation}
  SDLGraph_color = Record
                     r,g,b,a:Uint8;
                     i:Integer;
                     End;

  operator := (col:Integer) z:SDLGraph_color;
  operator := (col : SDLGraph_color) z: Integer;


{GRAPH declarations}
  procedure   InitGraph (var GraphDriver,GraphMode : integer; const PathToDriver : string);
  procedure   CloseGraph;
  function    GraphResult: SmallInt;
  function    GraphErrorMsg(ErrorCode: SmallInt):String;
  procedure   DetectGraph(var GraphDriver, GraphMode: Integer);
  function    GetMaxX:Integer;
  function    GetMaxY:Integer;
  procedure   SetColor(color:SDLGraph_color);
  function    GetColor: SDLGraph_color;
  procedure   PutPixel(X,Y: Integer; color: SDLGraph_color);inline;
  function    GetPixel(X, Y:Integer):SDLGraph_color;
  procedure   Line(X1,Y1, X2, Y2:Integer);
  procedure   OutTextXY(X,Y:Integer; S:String);
  procedure   SetFillStyle(Pattern:Word; Color:SDLgraph_color);
  procedure   FloodFill(X, Y:Integer; border:SDLgraph_color);
  procedure   Circle(X,Y:Integer; Radius:Word);
  function    TextWidth(S:String):Word;
  function    TextHeight(S:String):Word;
  function    ImageSize(X1,Y1, X2,Y2:Integer):Integer;
  procedure   GetImage(X1, Y1, X2, Y2:Integer; Var Bitmap);
  procedure   PutImage(X0,Y0:Integer; Var Bitmap; BitBlit:Word);
  procedure   ClearDevice;inline;

{SDLGraph extension declarations}

  procedure SDLGraph_SetWindowed(b:Boolean);
  function SDLGraph_MakeColor(r,g,b:Byte):SDLGraph_color;

IMPLEMENTATION

{$IFDEF unix}
Uses SDL, SDL_video, SDL_timer, cthreads;
{$ELSE}
Uses SDL, SDL_video, SDL_timer;
{$ENDIF}

Var
   screen:PSDL_Surface;
   SDLGraph_graphresult:SmallInt;
   SDLGraph_flags:Uint32;
   SDLGraph_curcolor,
   SDLGraph_bgcolor:Uint32;

{   EgaColors:Array[0..15] of SDLGraph_color;
   VgaColors:Array[0..255] of SDLGraph_color;
}
   gdriver:integer;
   must_be_locked:Boolean;
   drawing_thread_status:Integer;


Type
   PUint8  = ^Uint8;
   PUint16 = ^Uint16;
   PUint32 = ^Uint32;
   PByte   = ^Byte;
   PPSDL_Rect = ^PSDL_Rect;

    Procedure Swap(Var a,b:Integer);
      Begin
        a:= a + b;
        b:= a - b;
        a:= a - b;
      End;

    operator := (col:Integer) z:SDLGraph_color;
      Begin
        z.i:=col;
        with z do
          Begin
            case col of
              black:
                Begin
                  r:=0;g:=0;b:=0;
                End;
              blue:
                Begin
                  r:=0;
                  g:=0;
                  b:=200;
                End;
              green:
                Begin
                  r:=0;
                  g:=192;
                  b:=0;
                End;
              cyan:
                Begin
                  r:=0;
                  g:=192;
                  b:=192;
                End;
              red:
                Begin
                  r:=200;
                  g:=0;
                  b:=0;
                End;
              magenta:
                Begin
                  r:=150;
                  b:=0;
                  g:=150;
                End;
              brown:
                Begin
                  r:=192;
                  g:=96;
                  b:=64;
                End;
              lightgray:
                Begin
                  r:=192;
                  g:=192;
                  b:=192;
                End;
              darkgray:
                Begin
                  r:=96;
                  g:=96;
                  b:=96;
                End;
              lightblue:
                Begin
                  r:=90;
                  b:=90;
                  b:=255;
                End;
              lightgreen:
                Begin
                  r:=0;
                  g:=255;
                  b:=0;
                End;
              lightcyan:
                Begin
                  r:=0;
                  g:=255;
                  b:=255;
                End;
              lightred:
                Begin
                  r:=255;
                  g:=90;
                  b:=90;
                End;
              lightmagenta:
                Begin
                  r:=255;
                  g:=0;
                  b:=255;
                End;
              yellow:
                Begin
                  r:=255;
                  g:=255;
                  b:=0;
                End;
              white:
                Begin
                  r:=255;
                  b:=255;
                  g:=255;
                End;
              End;
            a:=0;
          End;
      End;

    operator := (col : SDLGraph_color) z: Integer;
      Begin
        z:=col.i mod 16;{that will make colors to be periodical value}
      End;

    {This 2 procedures will make conversions between SDL and SDLgraph color formats}
    function SDL_to_SDLgraph(sdlcol:Uint32): SDLgraph_color;
      Begin
        SDL_GetRGBA(sdlcol, screen^.format, SDL_to_SDLgraph.r, SDL_to_SDLgraph.g, SDL_to_SDLgraph.b, SDL_to_SDLgraph.a);
      End;

    function SDLgraph_to_SDL(col:SDLgraph_color): Uint32;
      Begin
        if(gdriver=D1bit) then
          Begin
            if(col.r=0) and (col.g=0) and (col.b=0) then
              SDLgraph_to_SDL:=SDL_MapRGB(screen^.format, 0,0,0)
            else
              SDLgraph_to_SDL:=SDL_MapRGB(screen^.format, 255,255,255);
          End
        else if(gdriver=D4bit) then
          Begin
            {some conversion actions}
          End
        else
          SDLgraph_to_SDL:=SDL_MapRGBA(screen^.format, col.r, col.g, col.b, col.a);
      End;

    procedure PutPixel_NoLock(X,Y: Integer; sdlcolor: Uint32); {local;}register;
      {Note: This procedure get sdlcolor as drawing value, not sdlgraph_color}
      Var p:PUint8;
          bpp:Uint8;
      Begin
        if(X<0) or (X>=screen^.w) or (Y<0) or (Y>=screen^.h) then
          Exit;
        bpp:=screen^.format^.BytesPerPixel;
        p:= PUint8(screen^.pixels) + Y * screen^.pitch + X * bpp;
        Case bpp of
          2: PUint16(p)^:=sdlcolor;
          4: PUint32(p)^:=sdlcolor;
          else
            Writeln('PutPixel_NoLock: Unknown bpp: ', bpp);
          End;
      End;

    procedure BeginDraw;inline;{local;}
      Begin
{        must_be_locked:=SDL_MUSTLOCK(screen);
        if must_be_locked then
          SDL_LockSurface(screen);
}      End;

    procedure EndDraw;inline;{local;}
      Begin
 {       if must_be_locked then
          SDL_UnlockSurface(screen);
}        SDL_Flip(screen);
      End;

    procedure SetFillStyle(Pattern:Word; Color:SDLgraph_color);
      Begin
        Writeln('SetFillStyle: stub');
      End;

    procedure OutTextXY(X,Y:Integer; S:String);
      Begin
        Writeln('OutTextXY: stub');
      End;

    procedure FloodFill(X, Y:Integer; border:SDLgraph_color);
      Begin
        Writeln('FloodFill: stub');
      End;

    procedure Circle(X,Y:Integer; Radius:Word);
      Begin
        Writeln('Circle: stub');
      End;

    function TextWidth(S:String):Word;
      Begin
        Writeln('TextWidth: stub');
      End;

    function TextHeight(S:String):Word;
      Begin
        Writeln('TextHeight: stub');
      End;

    function ImageSize(X1,Y1, X2,Y2:Integer):Integer;
      Begin
        ImageSize:= Abs((Y2-Y1)*(X2-X1)*(screen^.format^.BytesPerPixel));
      End;

    procedure GetImage(X1, Y1, X2, Y2:Integer; Var Bitmap);
      Var Y, X, D:Integer;
          bpp:Word;
          wp:^Word;
          p:^Byte;
      Begin
        if(X1=X2) or (Y1=Y2) then
          Exit;
        if(Y1>Y2) then
          Begin
            Swap(Y1, Y2);
            Swap(X1, X2);
          End;
        bpp:=screen^.format^.BytesPerPixel;
        wp := @Bitmap;
        wp^:= Abs(X2-X1);
        Inc(wp);
        wp^:= Y2-Y1;
        Inc(wp);
        wp^:=bpp;
        Inc(wp);
        p:=PByte(wp);
        for Y:=Y1 to Y2 do
          Begin
            if(X1>X2) then
              D:=-1
            else
              D:=+1;
            X:=X1;
            while(X<>X2) do
              Begin
                Case bpp of
                  1:
                    Begin
                      PUint8(p)^:=SDLgraph_to_SDL(GetPixel(X,Y));
                      Inc(p, 1);
                    End;
                  2:
                    Begin
                      PUint16(p)^:=SDLgraph_to_SDL(GetPixel(X,Y));
                      Inc(p,  2);
                    End;
                  4:
                    Begin
                      PUint32(p)^:=SDLgraph_to_SDL(GetPixel(X,Y));
                      Inc(p, 4);
                    End;
                  else
                    Writeln('GetImage: Unknown bpp ', bpp);
                  End;
                Inc(X, D);
              End;
          End;
      End;

    procedure PutImage(X0,Y0:Integer; Var Bitmap; BitBlit:Word);
      Var x,y, w,h,bpp:Word;
      wp:^Word;
      p:^Byte;
      syp, sxp:^Byte;
      color:Uint32;
      Begin
        wp:=@Bitmap;
        w:= wp^;
        Inc(wp);
        h:= wp^;
        Inc(wp);
        bpp:=wp^;
        Inc(wp);
        p:=PByte(wp);
        syp:=PByte(screen^.pixels) + Y0*screen^.pitch+X0*screen^.format^.BytesPerPixel;
        for y:=0 to h-1 do
            if((y+y0)<screen^.h) then
              Begin
                sxp:=syp;
                for x:=0 to w-1 do
                    Begin
                      Case bpp of
                        1: color:=Puint8(p)^;
                        2: color:=PUint16(p)^;
                        4: color:=PUint32(p)^;
                        else
                          Writeln('Unknown bpp: ', bpp);
                        End;
                      Inc(p, bpp);

                      Case screen^.format^.BytesPerPixel of
                        1:  Puint8(sxp)^:=color;
                        2: Puint16(sxp)^:=color;
                        4: Puint32(sxp)^:=color;
                        End;
                      Inc(sxp, screen^.format^.BytesPerPixel);
                    End;
                Inc(syp, screen^.pitch);
              End;
      End;


    procedure ClearDevice;inline;
      Begin
        SDL_FillRect(screen, Nil, SDLGraph_bgcolor);
      End;

    procedure PutPixel(X,Y: Integer; color: SDLGraph_color);inline;
      Var dw:Dword;
      Begin
        {dw:=SDL_GetTicks;}
        PutPixel_NoLock(X,Y, SDLgraph_to_SDL(color));
        {Writeln('PutPixel_NoLock: Time drawing: ', SDL_GetTicks-dw);}
      End;

    function GetPixel(X, Y:Integer):SDLGraph_color;
      Var p:PUint8;
          bpp:Uint8;
      Begin
        bpp:=screen^.format^.BytesPerPixel;
        p:= PUint8(screen^.pixels) + Y * screen^.pitch + X * bpp;
        Case bpp of
          2: GetPixel:=SDL_to_SDLgraph(PUint16(p)^);
          4: GetPixel:=SDL_to_SDLgraph(PUint32(p)^);
          else
            Writeln('GetPixel: Unknown bpp: ', bpp);
          End;
      End;

    procedure Line(X1,Y1, X2, Y2:Integer);
    {Can we use the FPC GRAPH source for fast algorithms for most of our primitives?}
      Var X:Integer;
      Begin
        BeginDraw;
        if(X1=X2) then
          Begin
            if(Y1>Y2) then
              Swap(Y1, Y2);
            for X:=Y2 downto Y1 do
              PutPixel_NoLock(X2, X, SDLGraph_curcolor);
          End
        else if(Y1=Y2) then
          Begin
            if(X1>X2) then
              Swap(X1, X2);
            for X:=X2 downto X1 do
              PutPixel_NoLock(X, Y2, SDLGraph_curcolor);
          End
        else if(Abs(X2-X1)>Abs(Y2-Y1)) then
          Begin
            if(X1>X2) then
              Begin
                Swap(X1,X2);
                Swap(Y1,Y2);
              End;
            for X:=X2 downto X1 do
              PutPixel_NoLock(X, Y1+Round((X-X1)*(Y2-Y1)/(X2-X1)), SDLGraph_curcolor);
          End
        else
          Begin
            if(Y1>Y2) then
              Begin
                Swap(X1,X2);
                Swap(Y1,Y2);
              End;
            for X:=Y2 downto Y1 do
              PutPixel_NoLock(X1+Round((X-Y1)*(X2-X1)/(Y2-Y1)), X, SDLGraph_curcolor);
          End;
        EndDraw;
      End;

    procedure SetColor(color:SDLGraph_color);
      Begin
         SDLGraph_curcolor:=SDLgraph_to_SDL(color);
      End;

    function GetColor: SDLGraph_color;
      Begin
        GetColor:=SDL_to_SDLgraph(SDLGraph_curcolor);
      End;

    function SDLGraph_MakeColor(r,g,b:Byte):SDLGraph_color;
      Begin
        SDLGraph_MakeColor.r := r;
        SDLGraph_MakeColor.g := g;
        SDLGraph_MakeColor.b := b;
      End;


    function GetMaxX:Integer;
      Begin
        GetMaxX:=screen^.w;
      End;
    function GetMaxY:Integer;
      Begin
        GetMaxY:=screen^.h;
      End;

    function GraphResult: SmallInt;
      Begin
        GraphResult:=SDLGraph_graphresult;
      End;

    function GraphErrorMsg(ErrorCode: SmallInt):String;
      Begin
        case SDLGraph_graphresult of
          0:  GraphErrorMsg:='Everything is OK';
          -1: GraphErrorMsg:='Detect has not found proper graphic mode';
          End;
      End;
    procedure DetectGraph(var GraphDriver, GraphMode: Integer);
      Var VI:PSDL_VideoInfo;
          bpp:Integer;
          ra: PPSDL_Rect;
      Begin
        Writeln('Begin of DetectGraph');
        ra:= PPSDL_Rect(SDL_ListModes(Nil, SDLGraph_flags));
        Writeln('DetectGraph: SDL_ListModes returned: ', Int64(ra));
        if(ra=Nil) then
          Begin
            SDLGraph_graphresult:=-1;
            Exit;
          End
        else
          Begin
              if(Int64(ra)<>-1) then
                with ra^[0] do
                  Begin
                  if (w=1024) and (h=768) then
                    GraphMode:=m1024x768
                  else if(w=800) and (h=600) then
                    GraphMode:=m800x600
                  else if(w=1280) and (h=1024) then
                    GraphMode:=m1280x1024
                  else if(w=1600) and (h=1200) then
                    GraphMode:=m1600x1200
                  else if(w=2048) and (h=1536) then
                    GraphMode:=m2048x1536
                  else if(w=640) and (h=480) then
                    GraphMode:=m640x480
                  else
                    Begin
                      Writeln('DetectGraph: This mode is unknown: ', w, 'x', h);
                      SDLGraph_graphresult:=-1;
                      Exit;
                    End;
                  End
              else
                GraphMode:=m2048x1536;
            VI:=SDL_GetVideoInfo;
            bpp:=VI^.vfmt^.BitsPerPixel;
            case bpp of
              16: GraphDriver:=D16bit;
              24: GraphDriver:=D24bit;
              32: GraphDriver:=D32bit;
              else
                Begin
                  Writeln('DetectGraph: This bpp is unknown: ', bpp);
                  SDLGraph_graphresult:=-1;
                  Exit;
                End;
              End;
          End;

        Writeln('End of DetectGraph');
      End;

    function DrawThread(p:Pointer)
{$IFDEF CPUX86_64 }
   :Int64;
{$ELSE}
   :LongInt;
{$ENDIF}
      Begin
        drawing_thread_status:=1;
        while drawing_thread_status<>0 do
          Begin
            SDL_Delay(40);
            {1000/25 - frame every 1/25 of second} {We don't need to update screen more frequently. Human eye can see only 25 fps}
            SDL_Flip(screen);
          End;
        drawing_thread_status:=-1;
        DrawThread:=0;
      End;

    Procedure InitGraph(var GraphDriver,GraphMode : integer; const PathToDriver : string);
      Var width, height, bpp:Integer;
      Begin
        Writeln('Begin of InitGraph');
        gdriver:=GraphDriver;
        SDL_Init(SDL_INIT_VIDEO);

      if GraphDriver=Detect then
        Begin
          DetectGraph(GraphDriver, GraphMode);
          if(SDLGraph_graphresult<>0) then Exit;
        End;

        case GraphDriver of
          D16bit: bpp:=16;
          D24bit: bpp:=24;
          D32bit: bpp:=32;
          End;
        case GraphMode of
        m640x480:
         Begin
           width:=640;
           height:=480
         End;
          m800x600:
            Begin
              width:=800;
              height:=600;
            End;
          m1024x768:
            Begin
              width:=1024;
              height:=768;
            End;
          m1280x1024:
            Begin
              width:=1280;
              height:=1024;
            End;
          m2048x1536:
            Begin
              width:=2048;
              height:=1536;
            End;
          m1600x1200:
            Begin
              width:=1600;
              height:=1200;
            End;
          End;

        Writeln('InitGraph: will now initialize with: ', width, 'x', height, ', ', bpp);
        screen:=SDL_SetVideoMode(width, height, bpp, SDLGraph_flags);
        SDLGraph_graphresult:=0;

        SDLGraph_bgcolor:=SDLgraph_to_SDL(Black);
        Writeln('Default background: ', SDLGraph_bgcolor);
        SDLGraph_curcolor:=SDLgraph_to_SDL(White);

        BeginThread(@DrawThread, Nil);
        Writeln('End of InitGraph');
      End;

    Procedure CloseGraph;
      Begin
        drawing_thread_status:=0;
        while drawing_thread_status<>-1 do;
        SDL_Quit;
      End;

    procedure SDLGraph_SetWindowed(b:Boolean);
      Begin
        if b then
          SDLGraph_flags:= SDLGraph_flags and (not SDL_FULLSCREEN)
        else
          SDLGraph_flags:= SDLGraph_flags or SDL_FULLSCREEN;
      End;


Begin
   screen:=Nil;
   SDLGraph_flags:=SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_FULLSCREEN;
   Writeln('SDLGraph initialized successful');
   drawing_thread_status:=0;
End.


