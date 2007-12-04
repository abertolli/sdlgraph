{This code is covered under the terms of the LGPL.}

UNIT SDLGraph;

{$inline on}
{$MODE OBJFPC}

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

{Bar3D constants}
  TopOn=true;
  TopOff=false;

Type
  FillPatternType  = Array[1..8] of Byte;
  FillSettingsType = Record
                       Pattern:Word;
                       Color:Uint32;
                       End;


{GRAPH declarations}
  procedure   InitGraph (var GraphDriver,GraphMode : integer; const PathToDriver : string = '');
  procedure   CloseGraph;
  function    GraphResult: SmallInt;
  function    GraphErrorMsg(ErrorCode: SmallInt):String;
  procedure   DetectGraph(var GraphDriver, GraphMode: Integer);
  function    GetMaxX:Integer;
  function    GetMaxY:Integer;

  procedure   SetColor(col:Integer);
  procedure   SetColor(r,g,b:Byte; a:Byte=0);

  procedure   SetBkColor(col:Integer);
  procedure   SetBkColor(r,g,b:Byte; a:Byte=0);

  function    GetColor: Integer;
  procedure   GetColor(Var r,g,b,a:Byte);

  procedure   PutPixel(X,Y:Integer; col:Integer);inline;
  procedure   PutPixel(X,Y:Integer; r,g,b:Byte; a:Byte = 0);

  function    GetPixel(X,Y:Integer):Integer;inline;
  procedure   GetPixel(X,Y:Integer; Var R,G,B,A:Byte);inline;

  procedure   MoveTo(X, Y:Integer);
  function    GetX:Integer;
  function    GetY:Integer;

  procedure   Line(X1,Y1, X2, Y2:Integer);
  procedure   LineTo(X, Y:Integer);
  procedure   LineRel(dX, dY:Integer);

  procedure   OutTextXY(X,Y:Integer; S:String);

  procedure   SetFillStyle(Pattern:Word; Color:Integer);inline;
  procedure   SetFillStyle(Pattern:Word; r,g,b,a:Byte);inline;

  procedure   SetFillPattern(Pattern:FillPatternType; Color:Integer);inline;
  procedure   SetFillPattern(Pattern:FillPatternType; r,g,b,a:Byte);inline;

  procedure   FloodFill(X, Y:Integer; border:Integer);inline;
  procedure   FloodFill(X, Y:Integer; r,g,b,a:Byte);inline;

  procedure   Circle(xc,yc:Integer; Radius:Word);
  procedure   Rectangle(X1,Y1,X2,Y2:Integer);

  procedure   Bar(X1, Y1, X2, Y2:Integer);
  procedure   Bar3D(X1, Y1, X2, Y2:Integer; Depth:Word; Top:Boolean);

  function    TextWidth(S:String):Word;
  function    TextHeight(S:String):Word;
  function    ImageSize(X1,Y1, X2,Y2:Integer):Integer;
  procedure   GetImage(X1, Y1, X2, Y2:Integer; Var Bitmap);
  procedure   PutImage(X0,Y0:Integer; Var Bitmap; BitBlit:Word);
  procedure   ClearDevice;inline;

{SDLGraph extension declarations}

  procedure SDLGraph_SetWindowed(b:Boolean);

IMPLEMENTATION

Uses SDL, SDL_video, SDL_timer, SdlGraph_Crt
{$IFDEF unix}
, cthreads
{$ENDIF}
;

Const
   PreDefPatterns:Array[0..11] of FillPatternType =
    (($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF),{EmptyFill}
     ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF),{SolidFill}
     ($FF, $FF,   0,   0, $FF, $FF,   0, 0  ),{LineFill}
     ($80, $40, $20, $10, $08, $04, $02, $01),{LtSlashFill}
     ($83, $C1, $E0, $70, $38, $1C, $0E, $07),{SlashFill}
     ($07, $0E, $1C, $38, $70, $E0, $C1, $83),{BkSlashFill}
     ($01, $02, $04, $08, $10, $20, $40, $80),{LtBkSlashFill}
     ($FF, $88, $88, $88, $FF, $88, $88, $88),{HatchFill}
     ($81, $42, $24, $18, $18, $24, $42, $81),{XHatchFill}
     ($CC, $33, $CC, $33, $CC, $33, $CC, $33),{InterLeaveFill}
     ($80,   0,  $8,   0, $80,   0,  $8,   0  ),{WideDotFill}
     ($88,   0,  $22,  0, $88,   0, $22,   0  ){CloseDotFill}
    );

Var
   screen:PSDL_Surface;
   SDLGraph_graphresult:SmallInt;
   SDLGraph_flags:Uint32;
   SDLGraph_curcolor,
   SDLGraph_bgcolor,
   SDLGraph_curfillcolor:Uint32;
   GraphicCursor:Record
                   X,Y:Integer;
                   End;
   cur_fillpattern:word;
   cur_userfillpattern :FillPatternType;

   EgaColors:Array[0..15] of Record
                               r,g,b:Byte
                               End;
{   VgaColors:Array[0..255] of SDLGraph_color;}

   gdriver:integer;
   //must_be_locked:Boolean;
   drawing_thread_status:LongInt;
   drawing_thread_id
   {$IFDEF CPUX86_64 }
    :qword;
   {$ELSE}
    :dword;
   {$ENDIF}

Type
   PUint8  = ^Uint8;
   PUint16 = ^Uint16;
   PUint32 = ^Uint32;
   PByte   = ^Byte;
   PPSDL_Rect = ^PSDL_Rect;


    procedure   MoveTo(X, Y:Integer);
      Begin
        if(X<0) then
          X:=0
        else if(X>=screen^.w) then
          X:= screen^.w-1;
        if(Y<0) then
          Y:=0
        else if(Y>=screen^.h) then
          Y:= screen^.h-1;
        GraphicCursor.X:=X;
        GraphicCursor.Y:=Y;
      End;
    function    GetX:Integer;
      Begin
        GetX:= GraphicCursor.X;
      End;
    function    GetY:Integer;
      Begin
        GetY:=GraphicCursor.Y;
      End;

    Procedure Swap(Var a,b:Integer);
      Begin
        a:= a + b;
        b:= a - b;
        a:= a - b;
      End;

{Color conversion functions}
    function RGB_to_GraphColor(r,g,b:Byte):Integer;
      Const max_rgb = 16777216;{2^24}
      Var dw:Dword;
      Begin
        dw:=r shl 16 + g shl 8 + b;
        dw:=Round(dw/max_rgb*16);
        RGB_to_GraphColor:=dw;
      End;

    procedure SDL_to_RGBA(col:Uint32; Var r,g,b,a:Byte);inline;
      Begin
        SDL_GetRGBA(col, screen^.format, r,g,b,a);
      End;

    function SDL_to_GraphColor(col:Uint32):Integer;
      Var r,g,b:Byte;
      Begin
        SDL_GetRGB(col, screen^.format, r,g,b);
        SDL_to_GraphColor:=RGB_to_GraphColor(r,g,b);
      End;

    function RGBA_to_SDL(r,g,b,a:Byte): Uint32;
      Var dw:Dword;
      Begin
        if(gdriver=D1bit) then
          Begin
            if(r=255) and (g=255) and (b=255) then
              RGBA_to_SDL:=SDL_MapRGBA(screen^.format, 255,255,255, a)
            else
              RGBA_to_SDL:=SDL_MapRGBA(screen^.format, 0,0,0, a);
          End
        else if(gdriver=D4bit) then
          Begin
            dw:=RGB_to_GraphColor(r,g,b);
            Writeln('Conversion to 4-bit resulted: ', dw);
            RGBA_to_SDL:=SDL_MapRGBA(screen^.format, EgaColors[dw].r, EgaColors[dw].g, EgaColors[dw].b, a);
          End
        else
          RGBA_to_SDL:=SDL_MapRGBA(screen^.format, r, g, b, a);
      End;

    function GraphColor_to_SDL(i:Integer):Uint32;inline;
      Begin
        //if(gdriver>=D4bit) then
          GraphColor_to_SDL:=SDL_MapRGBA(screen^.format, EgaColors[i].r, EgaColors[i].g, EgaColors[i].b, 0)
//        else
//          GraphColor_to_SDL:=0;{Need to do some conversions}
      End;
{End of color conversion functions}

    procedure PutPixel_Surface(X,Y:Integer; sdlcolor:Uint32; surf:PSDL_Surface);
      Var p:PUint8;
          bpp:Uint8;
      Begin
        if(X<0) or (X>=surf^.w) or (Y<0) or (Y>=surf^.h) then
          Exit;
        bpp:=surf^.format^.BytesPerPixel;
        p:= PUint8(surf^.pixels) + Y * surf^.pitch + X * bpp;
        Case bpp of
          2: PUint16(p)^:=sdlcolor;
          3,4: PUint32(p)^:=sdlcolor;
          else
            Writeln('PutPixel_Surface: Unknown bpp: ', bpp);
          End;
      End;

    procedure PutPixel_NoLock(X,Y: Integer; sdlcolor: Uint32);inline;
      Begin
        PutPixel_Surface(X,Y, sdlcolor, screen);
      End;

    procedure   PutPixel(X,Y:Integer; col:Integer);inline;
      Begin
        PutPixel_NoLock(X,Y, GraphColor_to_SDL(col));
      End;
    procedure   PutPixel(X,Y:Integer; r,g,b:Byte; a:Byte);inline;
      Begin
        PutPixel_NoLock(X,Y, RGBA_to_SDL(r,g,b,a));
      End;

    function GetPixel_local(X, Y:Integer):Uint32;
      Var p:PUint8;
          bpp:Uint8;
      Begin
        bpp:=screen^.format^.BytesPerPixel;
        p:= PUint8(screen^.pixels) + Y * screen^.pitch + X * bpp;
        Case bpp of
          2: GetPixel_local:=PUint16(p)^;//SDL_to_SDLgraph(PUint16(p)^);
          4: GetPixel_local:=PUint32(p)^;//SDL_to_SDLgraph(PUint32(p)^);
          else
            Writeln('GetPixel: Unknown bpp: ', bpp);
          End;
      End;

    function GetPixel(X,Y:Integer):Integer;inline;
      Begin
        GetPixel:=SDL_to_GraphColor(GetPixel_local(X,Y));
      End;
    procedure GetPixel(X,Y:Integer; Var R,G,B,A:Byte);inline;
      Begin
        SDL_to_RGBA(GetPixel_local(X,Y), R,G,B,A);
      End;

    procedure SetFillStyle_local(Pattern:Word; Color:Uint32);
      Begin
        cur_fillpattern:=Pattern;
        SDLGraph_curfillcolor:=Color;
      End;

    procedure   SetFillStyle(Pattern:Word; Color:Integer);inline;
      Begin
        SetFillStyle_local(Pattern, GraphColor_to_SDL(Color));
      End;
    procedure   SetFillStyle(Pattern:Word; r,g,b,a:Byte);inline;
      Begin
        SetFillStyle_local(Pattern, RGBA_to_SDL(r,g,b,a));
      End;

    procedure SetFillPattern_local(Pattern:FillPatternType; Color:Uint32);
      Begin
        cur_userfillpattern:=Pattern;
        SDLGraph_curfillcolor  :=Color;
      End;

    procedure   SetFillPattern(Pattern:FillPatternType; Color:Integer);inline;
      Begin
        SetFillPattern_local(Pattern, GraphColor_to_SDL(Color));
      End;
    procedure   SetFillPattern(Pattern:FillPatternType; r,g,b,a:Byte);inline;
      Begin
        SetFillPattern_local(Pattern, RGBA_to_SDL(r,g,b,a));
      End;

    procedure OutTextXY(X,Y:Integer; S:String);
      Begin
        Writeln('OutTextXY: stub');
      End;

    procedure FloodFill_color_pattern_surface(X0,Y0:word; BC, IC:Uint32;pattern:FillPatternType; surf:PSDL_Surface);
    {This function fills rect on surface, with color IC and border color BC, using pattern}
      Var StackX, StackY:Array of word;
          StackSize:LongInt;
          Top:LongInt = 0;
          pat_arr:Array[0..7] of Array[0..7] of boolean;
          x,x1,y:word;
          SpanUp, SpanDown:Boolean;
          col:Uint32;
      procedure PutPixel_FloodFill;inline;
        Begin
          if(pat_arr[y mod 8][x1 mod 8]) then
            Begin
              PutPixel_Surface(x1,y, IC, surf);
            End;
        End;
      function Pop(Var x,y:Word):Boolean;inline;
        Begin
          if(Top>0) then
            Begin
              Dec(Top);
              x:=StackX[Top];
              y:=StackY[Top];
              Pop:=true;
            End
          else
            Pop:=false;
        End;
      procedure Push(px,py:word);inline;
        Begin
          StackX[Top]:=px;
          StackY[Top]:=py;
          Inc(Top);
        End;

      procedure CheckUp;inline;
        Begin
          if(not SpanUp) and (y > 0) and (GetPixel_local(x1, y-1) <> BC) then
            Begin
              Push(x1, y - 1);
              SpanUp := true;
            End
          else if(SpanUp) and (y > 0) and (GetPixel_local(x1, y-1) = BC) then
              SpanUp := false;
        End;

      procedure CheckDown;inline;
        Begin
          if(not SpanDown) and (y < surf^.h - 1) and (GetPixel_local(x1, y+1) <> BC) then
            Begin
              push(x1, y + 1);
              SpanDown := true;
            End
          else if(SpanDown) and (y < surf^.h - 1) and (GetPixel_local(x1, y+1) = BC) then
              SpanDown := false;
        End;

      procedure GoScanning(up:Boolean);
        Begin
          While Pop(x,y) do
            Begin
              x1:=x;
              col:=GetPixel_local(x1,y);
              while(x1>0) and (col<>BC) and (col<>IC) do
                Begin
                  Dec(x1);
                  col:=GetPixel_local(x1,y);
                End;
              Inc(x1);
              if(up) then
                SpanUp:=false
              else
                SpanDown:=false;
              while(x1 < surf^.w) and (GetPixel_local(x1, y) <>BC) do
                Begin
                  PutPixel_FloodFill;
                  if(up) then
                    CheckUp
                  else
                    CheckDown;
                  Inc(x1);
                End;
            End;
        End;

      begin
        Writeln('FloodFill_color_pattern_surface: Border color: ', BC);
        for y:=0 to 7 do
          for x:=0 to 7 do
            pat_arr[y][x] := boolean(pattern[y+1] and ($01 shl x));
        StackSize:= surf^.w * surf^.h;
        SetLength(StackX, StackSize);
        SetLength(StackY, StackSize);
        Push(x0, y0);
        GoScanning(true);{Go scanning lines up}
        Top:=0;
        Push(x0,y0+1);
        GoScanning(false);{Then, go scanning down}
        {Scanning directions separation prevents endless looping and make the program to perform every line checking only once}
      end;

    {procedure FloodFill_color_pattern(X0,Y0:word; BC, IC:Uint32;pattern:FillPatternType);inline;
      Begin
        FloodFill_color_pattern_surface(X0,Y0, BC, IC, pattern, surf);
      End;
}
    procedure FloodFill_local_surface(X, Y:Integer; border:Uint32; surf:PSDL_Surface);
      Var fill_color:Uint32;
          pat:FillPatternType;
      Begin
        if(cur_fillpattern=EmptyFill) then
          fill_color:=SDLGraph_bgcolor
        else
          fill_color:=SDLGraph_curfillcolor;
        if(cur_fillpattern=UserFill) then
          pat:=cur_userfillpattern
        else
          pat:=PreDefPatterns[cur_fillpattern];
        FloodFill_color_pattern_surface(X,Y, border, fill_color, pat, surf);
      End;

      procedure   FloodFill(X, Y:Integer; border:Integer);inline;
        Begin
          FloodFill_local_surface(X,Y, GraphColor_to_SDL(border), screen);
        End;
      procedure   FloodFill(X, Y:Integer; r,g,b,a:Byte);inline;
        Begin
          FloodFill_local_surface(X,Y, RGBA_to_SDL(r,g,b,a), screen);
        End;

    procedure   Bar(X1, Y1, X2, Y2:Integer);
      Var tmpsurf:PSDL_Surface;
          rect:SDL_Rect;
      Begin
        Writeln('Bar: X1=', X1);
        Writeln('     Y1=', Y1);
        Writeln('     X2=', X2);
        Writeln('     Y2=', Y2);
        tmpsurf:=SDL_CreateRGBSurface(SDL_HWSURFACE or SDL_SRCCOLORKEY, Abs(X2-X1), Abs(Y2-Y1), screen^.format^.BitsPerPixel, 0,0,0,0);

        FloodFill_local_surface(0,0, $FFFFFF, tmpsurf);
        if(X1>X2) then
          rect.x:=X2
        else
          rect.x:=X1;

        if(Y1>Y2) then
          rect.y:=Y2
        else
          rect.y:=Y1;
        Writeln('Bar: X=', rect.X);
        Writeln('     Y=', rect.Y);
        SDL_BlitSurface(tmpsurf, Nil, screen, @rect);
      End;

    procedure   Bar3D(X1, Y1, X2, Y2:Integer; Depth:Word; Top:Boolean);
      Var LeftUp, RightUp, RightDown: Record
                                        x,y:Integer;
                                        End;
          Delta:Integer;
          cur_x, cur_y:Integer;
      Begin
        cur_x:=GetX;
        cur_y:=GetY;
        Bar(X1,Y1, X2, Y2);
        Rectangle(X1, Y1, X2, Y2);
        if(X1>X2) then
          Begin
            Swap(X1, X2);
            Swap(Y1, Y2);
          End;
        if(Y2>Y1) then
          Begin
            LeftUp.X:=X1;
            LeftUp.Y:=Y1;
            RightDown.X:=X2;
            RightDown.Y:=Y2;
            RightUp.X:=X2;
            RightUp.Y:=Y1;
          End
        else
          Begin
            LeftUp.X:=X1;
            LeftUp.Y:=Y2;
            RightUp.X:=X2;
            RightUp.Y:=Y2;
            RightDown.X:=X2;
            RightDown.Y:=Y1;
          End;
        if(Depth>0) then
          Begin
            Delta:= Round(Depth / sqrt(2));
            MoveTo(RightDown.X, RightDown.Y);
            LineRel(Delta, -Delta);
            LineRel(0, RightUp.Y-RightDown.Y);
            if(Top=TopOn) then
              Begin
                LineRel(LeftUp.X-RightUp.X, 0);
                LineRel(-Delta, Delta);
                MoveTo(RightUp.X, RightUp.Y);
                LineRel(Delta, -Delta);
              End;
          End;
        MoveTo(cur_x, cur_y);
      End;

    procedure Rectangle(X1,Y1,X2,Y2:Integer);
      Begin
        Line(X1, Y1, X1, Y2);
        Line(X1, Y2, X2, Y2);
        Line(X2, Y2, X2, Y1);
        Line(X2, Y1, X1, Y1);
      End;

    procedure Circle(xc,yc:Integer; Radius:Word);
      {taken from(on russian): http://www.codenet.ru/progr/video/alg/alg4.php}
      var x,y,d:integer;
      procedure sim(x,y:integer);
        begin
          putpixel_NoLock(x+xc,y+yc,SDLGraph_curcolor);
          putpixel_NoLock(x+xc,-y+yc,SDLGraph_curcolor);
          putpixel_NoLock(-x+xc,-y+yc,SDLGraph_curcolor);
          putpixel_NoLock(-x+xc,y+yc,SDLGraph_curcolor);
          putpixel_NoLock(y+xc,x+yc,SDLGraph_curcolor);
          putpixel_NoLock(y+xc,-x+yc,SDLGraph_curcolor);
          putpixel_NoLock(-y+xc,-x+yc,SDLGraph_curcolor);
          putpixel_NoLock(-y+xc,x+yc,SDLGraph_curcolor);
        end;
      begin
        d:=3-2*y;
        x:=0;
        y:=Radius;
        while(x <= y) do
          begin
          sim(x,y);
          if d<0    then d:=d+4*x+6
          else begin
          d:=d+4*(x-y)+10;
          dec(y)
          end;
        inc(x)
        end;
      end;

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
                      PUint8(p)^:=GetPixel_local(X,Y);
                      Inc(p, 1);
                    End;
                  2:
                    Begin
                      PUint16(p)^:=GetPixel_local(X,Y);
                      Inc(p,  2);
                    End;
                  4:
                    Begin
                      PUint32(p)^:=GetPixel_local(X,Y);
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

    procedure Line(X1,Y1, X2, Y2:Integer);
    {Can we use the FPC GRAPH source for fast algorithms for most of our primitives?}
      Var X:Integer;
      Begin
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
      End;

    procedure   LineTo(X, Y:Integer);
      Begin
        Line(GraphicCursor.X, GraphicCursor.Y, X, Y);
        MoveTo(X,Y);
      End;
    procedure   LineRel(dX, dY:Integer);
      Begin
        Line(GraphicCursor.X, GraphicCursor.Y, GraphicCursor.X+dX, GraphicCursor.Y+dY);
        Inc(GraphicCursor.X, dX);
        Inc(GraphicCursor.Y, dY);
      End;

    procedure   SetColor(col:Integer);
      Begin
        SDLGraph_curcolor:=GraphColor_to_SDL(col);
      End;
    procedure   SetColor(r,g,b,a:Byte);
      Begin
        SDLGraph_curcolor:=RGBA_to_SDL(r,g,b,a);
      End;

    procedure   SetBkColor(col:Integer);
      Begin
        SDLGraph_bgcolor:=GraphColor_to_SDL(col);
      End;
    procedure   SetBkColor(r,g,b:Byte; a:Byte=0);
      Begin
        SDLGraph_bgcolor:=RGBA_to_SDL(r,g,b,a);
      End;

    function    GetColor: Integer;
      Begin
        GetColor:=SDL_to_GraphColor(SDLGraph_curcolor);
      End;
    procedure   GetColor(Var r,g,b,a:Byte);
      Begin
        SDL_to_RGBA(SDLGraph_curcolor, r,g,b,a);
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
                  else if(w=320) and (h=256) then
                    GraphMode:=m320x256
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
            //SDL_Delay(10);
            {SDL_UnLockSurface(screen);}
            {1000/25 - frame every 1/25 of second} {We don't need to update screen more frequently. Human eye can see only 25 fps}
            SDL_Flip(screen);
            {SDL_LockSurface(screen);}
          End;
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
          D4bit, D24bit: bpp:=24;
          D32bit: bpp:=32;
          End;
        case GraphMode of
          m640x480:
            Begin
              width:=640;
              height:=480
            End;
          m320x256:
            Begin
              width:=320;
              height:=256;
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

        SDLGraph_bgcolor:=GraphColor_to_SDL(Black);
        Writeln('Default background: ', SDLGraph_bgcolor);
        SDLGraph_curcolor:=GraphColor_to_SDL(White);

        SDLGraph_curfillcolor:=SDLGraph_curcolor;

        BeginThread(@DrawThread, Nil, drawing_thread_id);
        Writeln('End of InitGraph');
      End;

    Procedure CloseGraph;
      Begin
        InterLockedDecrement(drawing_thread_status);
        WaitForThreadTerminate(drawing_thread_id, 5000);
        Writeln('CloseGraph: Shutting down SDL');
        SDL_Quit;
        Writeln('CloseGraph: done');
      End;

    procedure SDLGraph_SetWindowed(b:Boolean);
      Begin
        if b then
          SDLGraph_flags:= SDLGraph_flags and (not SDL_FULLSCREEN)
        else
          SDLGraph_flags:= SDLGraph_flags or SDL_FULLSCREEN;
      End;

Var c:Integer;
Begin
  screen:=Nil;
  SDLGraph_flags:=SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_FULLSCREEN;
  Writeln('SDLGraph initialized successful');
  drawing_thread_status:=0;
  with EgaColors[black] do
    Begin
      r:=0;g:=0;b:=0;
    End;
  with EgaColors[blue] do
    Begin
      r:=0;g:=0;b:=200;
    End;
  with EgaColors[green] do
    Begin
      r:=0;g:=192;b:=0;
    End;
  with EgaColors[cyan] do
    Begin
      r:=0;g:=192;b:=192;
    End;
  with EgaColors[red] do
    Begin
      r:=200;g:=0;b:=0;
    End;
  with EgaColors[magenta] do
    Begin
      r:=150;b:=0;g:=150;
    End;
  with EgaColors[brown] do
    Begin
      r:=192;g:=96;b:=64;
    End;
  with EgaColors[lightgray] do
    Begin
      r:=192;g:=192;b:=192;
    End;
  with EgaColors[darkgray] do
    Begin
      r:=96;g:=96;b:=96;
    End;
  with EgaColors[lightblue] do
    Begin
      r:=90;b:=90;b:=255;
    End;
  with EgaColors[lightgreen] do
    Begin
      r:=0;g:=255;b:=0;
    End;
  with EgaColors[lightcyan] do
    Begin
      r:=0;g:=255;b:=255;
    End;
  with EgaColors[lightred] do
    Begin
      r:=255;g:=90;b:=90;
    End;
  with EgaColors[lightmagenta] do
    Begin
      r:=255;g:=0;b:=255;
    End;
  with EgaColors[yellow] do
    Begin
      r:=255;g:=255;b:=0;
    End;
  with EgaColors[white] do
    Begin
      r:=255;b:=255;g:=255;
    End;

  cur_fillpattern:=SolidFill;
End.
