Unit SDLGraph;

interface
  Const Detect=0;
  Const SDLGraph_FullScreen=0;
  Const SDLGraph_Windowed  =1;
  Const SDLGraph_Special   =2;

  Procedure InitGraph (var GraphDriver,GraphMode : integer; const PathToDriver : string);

  Procedure SDLGraph_SetSpecialWM(width, height, bpp:Integer; fullscreen:Boolean);
  { SDLGraph_SetSpecialWM is not part of the GRAPH spec... }

  Procedure CloseGraph;

implementation
  Uses SDL, SDL_video, SDL_types;

  Var screen:PSDL_Surface;
      spec_w, spec_h, spec_bp:Integer;
      spec_fs:Boolean;

  Procedure ResetScreen(width, height, bpp:Integer; fullscreen: Boolean);
    Var flags:Uint32;
    Begin
      if fullscreen then flags:=SDL_FULLSCREEN
      else               flags:=0;
      screen:=SDL_SetVideoMode(width, height, bpp, SDL_HWSURFACE or flags);
    End;

  Procedure SDLGraph_SetSpecialWM(width, height, bpp:Integer; fullscreen:Boolean);
    Begin
      spec_w:=width;
      spec_h:=height;
      spec_bp:=bpp;
      spec_fs:=fullscreen;
      if (screen<>Nil) then
        ResetScreen(width, height, bpp, fullscreen);
    End;

{ I should be able to call InitGraph with the standard constants from the GRAPH Unit, and I should know nothing about the internal SDLGraph constants!  I should also be able to pass in 0 for GraphDriver and GraphMode for autodetect.}

    Procedure InitGraph(var GraphDriver,GraphMode : integer; const PathToDriver : string);
      Begin
        SDL_Init(SDL_INIT_VIDEO);
        Case GraphMode of
          SDLGraph_FullScreen: ResetScreen(640, 480, 16, true);
          SDLGraph_Windowed:   ResetScreen(640, 480, 16, false);
          SDLGraph_Special:    ResetScreen(spec_w, spec_h, spec_bp, spec_fs);
        End;
      End;

    Procedure CloseGraph;
      Begin
        SDL_Quit;
      End;
Begin
  screen:=Nil;
End.
