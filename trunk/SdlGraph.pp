Unit SDLGraph;

{$inline on}

interface
Uses SDL_types;
{ Public things and function prototypes }

Const

   SDLgraph_version = '0.1';


{ Constants for mode selection }

   Detect=0;
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
Type
  SDLgraph_color = Uint32;

  Procedure InitGraph (var GraphDriver,GraphMode : integer; const PathToDriver : string);

  Procedure CloseGraph;

  function GraphResult: SmallInt;

  function GraphErrorMsg(ErrorCode: SmallInt):String;

  procedure DetectGraph(var GraphDriver, GraphMode: Integer);

  procedure SDLgraph_SetWindowed(b:Boolean);

  function GetMaxX:Integer;
  function GetMaxY:Integer;

  procedure SetColor(color:SDLgraph_color);
  function GetColor: SDLgraph_color;

  function SDLgraph_MakeColor(r,g,b:Byte):SDLgraph_color;

  function Black:SDLgraph_color;inline;
  function Blue:SDLgraph_color;inline;
  function Green:SDLgraph_color;inline;
  function Cyan:SDLgraph_color;inline;
  function Red:SDLgraph_color;inline;
  function Magenta:SDLgraph_color;inline;
  function Brown:SDLgraph_color;inline;
  function LightGray:SDLgraph_color;inline;
  function White:SDLgraph_color;inline;

  procedure PutPixel(X,Y: Integer; color: SDLgraph_color);inline;

  function GetPixel(X, Y:Integer):SDLgraph_color;

  procedure Line(X1,Y1, X2, Y2:Integer);

  function ImageSize(X1,Y1, X2,Y2:Integer):Integer;

  procedure GetImage(X1, Y1, X2, Y2:Integer; Var Bitmap);

  procedure PutImage(X0,Y0:Integer; Var Bitmap; BitBlit:Word);

  procedure ClearDevice;inline;

implementation
  Uses SDL, SDL_video, SDL_timer
    {$IFDEF unix}
     , cthreads
    {$ENDIF}
  ;

  Var screen:PSDL_Surface;
      sdlgraph_graphresult:SmallInt;
      sdlgraph_flags:Uint32;
      sdlgraph_curcolor,
       sdlgraph_bgcolor:SDLgraph_color;
      EgaColors:Array[0..15] of SDLgraph_color;
      must_be_locked:Boolean;
      drawing_thread_status:Integer;

  Type
    PUint8  = ^Uint8;
    PUint16 = ^Uint16;
    PUint32 = ^Uint32;
    PByte   = ^Byte;

    procedure Swap(Var a,b:Integer);
      Begin
        a:= a + b;
        b:= a - b;
        a:= a - b;
      End;

    procedure PutPixel_NoLock(X,Y: Integer; color: SDLgraph_color);local;register;
      Var p:PUint8;
          bpp:Uint8;
      Begin
        if(X<0) or (X>=screen^.w) or (Y<0) or (Y>=screen^.h) then
          Exit;
        bpp:=screen^.format^.BytesPerPixel;
        p:= PUint8(screen^.pixels) + Y * screen^.pitch + X * bpp;
        Case bpp of
          2: PUint16(p)^:=color;
          4: PUint32(p)^:=color;
          else
            Writeln('PutPixel_NoLock: Unknown bpp: ', bpp);
          End;
      End;

    procedure BeginDraw;inline;local;
      Begin
{        must_be_locked:=SDL_MUSTLOCK(screen);
        if must_be_locked then
          SDL_LockSurface(screen);
}      End;

    procedure EndDraw;inline;local;
      Begin
 {       if must_be_locked then
          SDL_UnlockSurface(screen);
}        SDL_Flip(screen);
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
                      PUint8(p)^:=GetPixel(X,Y);
                      Inc(p, 1);
                    End;
                  2:
                    Begin
                      PUint16(p)^:=GetPixel(X,Y);
                      Inc(p,  2);
                    End;
                  4:
                    Begin
                      PUint32(p)^:=GetPixel(X,Y);
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
      color:SDLgraph_color;
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


    procedure ClearDevice;
      Begin
        SDL_FillRect(screen, Nil, SDLgraph_bgcolor);
      End;

    procedure PutPixel(X,Y: Integer; color: SDLgraph_color);
      Var dw:Dword;
      Begin
//        dw:=SDL_GetTicks;
        PutPixel_NoLock(X,Y, color);
//        Writeln('PutPixel_NoLock: Time drawing: ', SDL_GetTicks-dw);
      End;

    function GetPixel(X, Y:Integer):SDLgraph_color;
      Var p:PUint8;
          bpp:Uint8;
      Begin
        bpp:=screen^.format^.BytesPerPixel;
        p:= PUint8(screen^.pixels) + Y * screen^.pitch + X * bpp;
        Case bpp of
          2: GetPixel:=PUint16(p)^;
          4: GetPixel:=PUint32(p)^;
          else
            Writeln('GetPixel: Unknown bpp: ', bpp);
          End;
      End;

    procedure Line(X1,Y1, X2, Y2:Integer);
      Var X:Integer;
      Begin
        BeginDraw;
        if(X1=X2) then
          Begin
            if(Y1>Y2) then
              Swap(Y1, Y2);
            for X:=Y2 downto Y1 do
              PutPixel_NoLock(X2, X, SDLgraph_curcolor);
          End
        else if(Y1=Y2) then
          Begin
            if(X1>X2) then
              Swap(X1, X2);
            for X:=X2 downto X1 do
              PutPixel_NoLock(X, Y2, SDLgraph_curcolor);
          End
        else if(Abs(X2-X1)>Abs(Y2-Y1)) then
          Begin
            if(X1>X2) then
              Begin
                Swap(X1,X2);
                Swap(Y1,Y2);
              End;
            for X:=X2 downto X1 do
              PutPixel_NoLock(X, Y1+Round((X-X1)*(Y2-Y1)/(X2-X1)), SDLgraph_curcolor);
          End
        else
          Begin
            if(Y1>Y2) then
              Begin
                Swap(X1,X2);
                Swap(Y1,Y2);
              End;
            for X:=Y2 downto Y1 do
              PutPixel_NoLock(X1+Round((X-Y1)*(X2-X1)/(Y2-Y1)), X, SDLgraph_curcolor);
          End;
        EndDraw;
      End;

    procedure SetColor(color:SDLgraph_color);
      Begin
        sdlgraph_curcolor:=color;
      End;

    function GetColor: SDLgraph_color;
      Begin
        GetColor:=sdlgraph_curcolor;
      End;

    function SDLgraph_MakeColor(r,g,b:Byte):SDLgraph_color;
      Begin
        SDLgraph_MakeColor:= SDL_MapRGB(screen^.format, r, g, b);
        Writeln('SDLgraph_MakeColor: done');
      End;

    function Black:SDLgraph_color;
      Begin
        Black:=EgaColors[0];
      End;
    function Blue:SDLgraph_color;
      Begin
        Blue:=EgaColors[6];
      End;
    function Green:SDLgraph_color;
      Begin
        Green:=EgaColors[4];
      End;
    function Cyan:SDLgraph_color;
      Begin
        Cyan:=EgaColors[5];
      End;
    function Red:SDLgraph_color;
      Begin
        Red:=EgaColors[2];
      End;
    function Magenta:SDLgraph_color;
      Begin
        Magenta:=EgaColors[7];
      End;
    function Brown:SDLgraph_color;
      Begin
        Brown:=EgaColors[3];
      End;
    function LightGray:SDLgraph_color;
      Begin
        LightGray:=EgaColors[1];
      End;
    function White:SDLgraph_color;
      Begin
        White:=EgaColors[8];
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
        GraphResult:=sdlgraph_graphresult;
      End;

    function GraphErrorMsg(ErrorCode: SmallInt):String;
      Begin
        case sdlgraph_graphresult of
          0:  GraphErrorMsg:='Everything is OK';
          -1: GraphErrorMsg:='Detect has not found proper graphic mode';
          End;
      End;
    procedure DetectGraph(var GraphDriver, GraphMode: Integer);
      Var VI:PSDL_VideoInfo;
          bpp:Integer;
          ra: PSDL_RectArray;
      Begin
        Writeln('Begin of DetectGraph');
        ra:= SDL_ListModes(Nil, sdlgraph_flags);
        Writeln('DetectGraph: SDL_ListModes returned: ', Int64(ra));
        if(ra=Nil) then
          Begin
            sdlgraph_graphresult:=-1;
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
                      sdlgraph_graphresult:=-1;
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
                  sdlgraph_graphresult:=-1;
                  Exit;
                End;
              End;
          End;

        Writeln('End of DetectGraph');
      End;

    function DrawThread(p:Pointer):int64;
      Begin
        drawing_thread_status:=1;
        while drawing_thread_status<>0 do
          Begin
            SDL_Delay(40);{1000/25 - frame every 1/25 of second}
            SDL_Flip(screen);
          End;
        drawing_thread_status:=-1;
        DrawThread:=0;
      End;

    Procedure InitGraph(var GraphDriver,GraphMode : integer; const PathToDriver : string);
      Var width, height, bpp:Integer;
      Begin
        Writeln('Begin of InitGraph');
	SDL_Init(SDL_INIT_VIDEO);

	if GraphDriver=Detect then
	  Begin
	    DetectGraph(GraphDriver, GraphMode);
	    if(sdlgraph_graphresult<>0) then Exit;
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
        screen:=SDL_SetVideoMode(width, height, bpp, sdlgraph_flags);
        sdlgraph_graphresult:=0;
        Writeln('Now will generate standart ega colors');
        EgaColors[0]:=SDLgraph_MakeColor(0,0,0);
        EgaColors[1]:=SDLgraph_MakeColor(128,128,128);
        EgaColors[2]:=SDLgraph_MakeColor(128,0,0);
        EgaColors[3]:=SDLgraph_MakeColor(128,128,0);
        EgaColors[4]:=SDLgraph_MakeColor(0,128,0);
        EgaColors[5]:=SDLgraph_MakeColor(0,128,128);
        EgaColors[6]:=SDLgraph_MakeColor(0,0,128);
        EgaColors[7]:=SDLgraph_MakeColor(128,0,128);
        EgaColors[8]:=SDLgraph_MakeColor(255,255,255);
        EgaColors[9]:=SDLgraph_MakeColor(192,192,192);
        EgaColors[10]:=SDLgraph_MakeColor(255,0,0);
        EgaColors[11]:=SDLgraph_MakeColor(255,255,0);
        EgaColors[12]:=SDLgraph_MakeColor(0,255,0);
        EgaColors[13]:=SDLgraph_MakeColor(0,255,255);
        EgaColors[14]:=SDLgraph_MakeColor(0,0,255);
        EgaColors[15]:=SDLgraph_MakeColor(255,0,255);
        Writeln('End of ega colors generating');
        sdlgraph_bgcolor:=EgaColors[0];
        sdlgraph_curcolor:=EgaColors[8];
        BeginThread(@DrawThread, Nil);
        Writeln('End of InitGraph');
      End;

    Procedure CloseGraph;
      Begin
        drawing_thread_status:=0;
        while drawing_thread_status<>-1 do;
        SDL_Quit;
      End;

    procedure SDLgraph_SetWindowed(b:Boolean);
      Begin
        if b then
          sdlgraph_flags:= sdlgraph_flags and (not SDL_FULLSCREEN)
        else
          sdlgraph_flags:= sdlgraph_flags or SDL_FULLSCREEN;
      End;


Begin
  screen:=Nil;
  sdlgraph_flags:=SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_FULLSCREEN;
  Writeln('SdlGraph initialized successful');
  drawing_thread_status:=0;
End.
