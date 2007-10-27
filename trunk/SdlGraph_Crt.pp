Unit SdlGraph_Crt;

interface

  function ReadKey: Char;

  function KeyPressed: Boolean;

implementation

  Uses SDL, Sdl_Events, SDL_Keyboard, cthreads;

  Var buffer: Array[0..255] of Char;
      point: ShortInt;

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
    Var c:Char;
    Begin
      Repeat until point=0;
      c:=buffer[point-1];
      Dec(point);
      Readkey:=c;
    End;

  function KeyPressed: Boolean;
    Begin
      Writeln('Keypressed called. point is ', point);
      if(point=0) then
        KeyPressed:=false
      else
        KeyPressed:=true;
    End;

//  Var EventProc_exit:Boolean;
  function EventProc( parameter: pointer):PtrInt;
    Var event:SDL_Event;
        key:SDLKey;
    Begin
      Writeln('Begin of EventProc');
      while true do
        if((SDL_WasInit(SDL_INIT_VIDEO) and SDL_INIT_VIDEO)<>0) then
          Begin
            SDL_WaitEvent(@event);
            if(event.eventtype=SDL_KEYUP) then
              Begin
                if(point<256) then
                  Begin
                    key:=event.key.keysym.sym;
                    Writeln('EventProc: Got key press: symcode=', key);
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
                  End;
              End
            else if(event.eventtype<>0) then
              Writeln('EventProc: Other event caught: ', event.eventtype);
          End;
      EventProc:=0;
    End;
  Var thid: TThreadID;
Begin
  SDL_SetEventFilter(@EventFilter);
  //EventProc_exit:=false;
  point:=0;
  thid:= BeginThread(@EventProc);
  Writeln('SdlGraph_Crt initialized successful');
End.
