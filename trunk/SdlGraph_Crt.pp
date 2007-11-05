Unit SdlGraph_Crt;

interface

  function ReadKey: Char;

  function KeyPressed: Boolean;

  procedure Delay(MS: DWord);

implementation

  Uses 
     SDL, Sdl_Events, SDL_Keyboard, SDL_timer
  {$IFNDEF WIN32}
     , cthreads
  {$ENDIF}
  ;

  Var buffer: Array[0..255] of Char;
      point: ShortInt;

  procedure Delay(MS: DWord);
    Begin
      SDL_Delay(MS);
    End;

  procedure ProcEvent(event:PSDL_Event);
    Var key:SDLKey;
    Begin
      if(point < 256) and (event^.eventtype=SDL_KEYUP) then
        Begin
          key:=event^.key.keysym.sym;
          Writeln('ProcEvent: Got key press: symcode=', key);
          if(key>=256) then
            Begin
              buffer[point]   := Char(key and $FF);
              buffer[point+1] := #0;
              Inc(point, 2);
            End
          else
            Begin
              buffer[point] := Char(key);
              Inc(point);
            End;
          Writeln('ProcEvent: done');
        End;
    End;

  function EventFilter(event:pSDL_Event):longint;cdecl;
    Begin
      case event^.eventtype of
        SDL_KEYUP:
          EventFilter:=1;
        else
          EventFilter:=0;
        End;
    End;

  function ReadKey: Char;
    Var event: SDL_Event;
    Begin
      while point=0 do
        Begin
          SDL_WaitEvent(@event);
          ProcEvent(@event);
        End;
      Dec(point);
      Readkey:=buffer[point];
    End;

  function KeyPressed: Boolean;
    Var event:SDL_Event;
    Begin
      while(SDL_PollEvent(@event)=1) do
          ProcEvent(@event);
      if(point=0) then
        KeyPressed:=false
      else
        KeyPressed:=true;
    End;

Begin
  SDL_SetEventFilter(@EventFilter);
  //EventProc_exit:=false;
  point:=0;
  Writeln('SdlGraph_Crt initialized successful');
End.
