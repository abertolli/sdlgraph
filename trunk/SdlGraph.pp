Unit SDLGraph;

interface

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



  Procedure InitGraph (var GraphDriver,GraphMode : integer; const PathToDriver : string);

  Procedure CloseGraph;

  function GraphResult: SmallInt;

  function GraphErrorMsg(ErrorCode: SmallInt):String;

  procedure DetectGraph(var GraphDriver, GraphMode: Integer);

  procedure SDLgraph_SetWindowed(b:Boolean);

implementation
  Uses SDL, SDL_video, SDL_types;

  Var screen:PSDL_Surface;
      sdlgraph_graphresult:SmallInt;
      sdlgraph_flags:Uint32;

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
        Writeln('DetectGraph: SDL_ListModes returned: ', Integer(ra));
        if(ra=Nil) then
          Begin
          sdlgraph_graphresult:=-1;
          Exit;
          End
        else
          Begin
              if(Integer(ra)<>-1) then
                with ra^[0] do
                  Begin
                  if (x=1024) and (y=768) then
                    GraphMode:=m1024x768
                  else if(x=800) and (y=600) then
                    GraphMode:=m800x600
                  else if(x=1280) and (y=1024) then
                    GraphMode:=m1280x1024
                  else if(x=1600) and (y=1200) then
                    GraphMode:=m1600x1200
                  else if(x=2048) and (y=1536) then
                    GraphMode:=m2048x1536
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
        Writeln('End of InitGraph');
      End;

    Procedure CloseGraph;
      Begin
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
  sdlgraph_flags:=SDL_HWSURFACE;
  Writeln('SdlGraph initialized successful');
End.
