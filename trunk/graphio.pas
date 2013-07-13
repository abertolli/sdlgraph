{
	GRAPHIO.PAS
	Copyright (C) 2002-2010 Angelo Bertolli
    Copyright (C) 2013 Angelo Bertolli
}

Unit GraphIO;

INTERFACE

uses
	sdl, sdl_gfx, sdl_ttf, sdlutils, dataio;

const

    {display settings}
    displaywidth    =   640;
    displayheight   =   480;
    colordepth      =   32;


    {legacy text identifiers}
    default        =    0;
    triplex        =    1;
    small          =    2;
    sanseri        =    3;
    gothic         =    4;

    horizontal     =    0;
    vertical       =    1;

    {legacy fill patterns - not supported}
    solidfill       =   1;

    {legacy color values}
    black           =   0;
    blue            =   1;
    green           =   2;
    cyan            =   3;
    red             =   4;
    magenta         =   5;
    brown           =   6;
    lightgray       =   7;
    darkgray        =   8;
    lightblue       =   9;
    lightgreen      =   10;
    lightcyan       =   11;
    lightred        =   12;
    lightmagenta    =   13;
    yellow          =   14;
    white           =   15;

    xhome           =   10;
    yhome           =   10;

type
    color_index     =   array[black..white] of byte;

var
    screen          :   pSDL_Surface;
    r               :   color_index;
    g               :   color_index;
    b               :   color_index;
    fgcolor         :   word;
    bgcolor         :   word;
    textfont        :   word;
    textdirection   :   word;
    textsize        :   word;
    cursorx         :   word;
    cursory         :   word;
    fontpath        :   string;
    fillpattern     :   word;
    fillcolor       :   word;

{legacy support}
function getpixel(x,y:smallint):word;
procedure setcolor(color:integer);
function getcolor:byte;
procedure settextstyle(font,direction,charsize:word);
procedure outtextxy(x,y:word;s:string);
function textwidth(s:string):word;
function textheight(s:string):word;
procedure cleardevice;
procedure setfillstyle(pattern,color:word);
procedure line(x1,y1,x2,y2:smallint);
procedure bar(x1,y1,x2,y2:smallint);
procedure rectangle(x1,y1,x2,y2:smallint);
procedure fillellipse(x1,y1:smallint;xradius,yradius:word);
function getmaxx:smallint;
function getmaxy:smallint;
function keypressed:boolean;
procedure delay(ms:word);

function readarrowkey:char;
procedure prompt;
procedure homecursor(var cursorx,cursory:integer);
procedure centerwrite(x,y:integer;s:string);
procedure graphwrite(var x,y:integer;s:string);
procedure graphwriteln(var x,y:integer;s:string);
procedure graphread(var x,y:integer;var s:string);
procedure drawpicturebyline(beginx,beginy:integer;dosname:string);
procedure writefile(beginy:integer;dosname:string);
procedure openscreen;
procedure closescreen;

IMPLEMENTATION
{--------------------------------------------------------------------------}
function getpixel(x,y:smallint):word;

var
    pixr    :   byte;
    pixg    :   byte;
    pixb    :   byte;
    loop    :   byte;
    colornum:   word;
    pixel   :   longword;

begin
    SDL_LockSurface(screen);
    pixel:=SDL_GetPixel(screen,x,y);
    SDL_GetRGB(pixel,screen^.format,@pixr,@pixg,@pixb);
    SDL_UnlockSurface(screen);
    colornum:=white+1;
    for loop:=black to white do
        if ((pixr = r[loop]) and (pixg = g[loop]) and (pixb = b[loop])) then
            colornum := loop;
    if (colornum > white) then
    begin
        writeln('Error: getpixel - unable to determine color.');
        halt(1);
    end;
    getpixel:=colornum;
end;
{--------------------------------------------------------------------------}
procedure setcolor(color:integer);

begin
    if (color in [black..white]) then fgcolor:=color;
end;
{--------------------------------------------------------------------------}
function getcolor:byte;

begin
    getcolor:=fgcolor;
end;
{--------------------------------------------------------------------------}
procedure settextstyle(font,direction,charsize:word);

begin
    if (font in [default..gothic]) then textfont:=font;
    if (direction in [horizontal..vertical]) then textdirection:=direction;
    if (direction = vertical) then writeln('Warning: vertical text not supported.');
    if (charsize in [0..8]) then textsize:=charsize;
end;
{--------------------------------------------------------------------------}
function getSDLfontfile     :   string;

var
    fontfile        :   string;

begin

    case textfont of
        triplex     :fontfile:='triplex.ttf';
        small       :fontfile:='small.ttf';
        sanseri     :fontfile:='sanseri.ttf';
        gothic      :fontfile:='gothic.ttf';
    else
        fontfile:='default.ttf';
    end;
    if not(exist(fontfile)) then fontfile:=fontpath+'/'+fontfile;
    getSDLfontfile:=fontfile;

end;
{--------------------------------------------------------------------------}
function getSDLfontsize     :   word;

const
    scale           =   8; {converts legacy sizes to pts}

var
    size            :   word;

begin
    size:=textsize * scale;
    if (size = 0) then size:=4 * scale;
    getSDLfontsize:=size;
end;
{--------------------------------------------------------------------------}
procedure openFont(var fontface:pointer);
{Starts TTF and returns the appropriate font from settextstyle }

var
    fontfile        :   string;
    fontsize        :   word;

begin
    if (TTF_init < 0) then
    begin
        writeln('Error: couldn''t initialize TTF.');
        halt(1);
    end;
    fontsize:=getSDLfontsize;
    fontfile:=getSDLfontfile;
    fontfile:=fontfile+#0#0;      {Some trickery because they want a pChar}
    fontface:=TTF_OpenFont(@fontfile[1],fontsize);
    if (fontface = nil) then
    begin
        writeln('Error: error opening font. '+fontfile);
        halt(1);
    end;
end;
{--------------------------------------------------------------------------}
procedure closeFont(var fontface:pointer);

begin
    TTF_CloseFont(fontface);
    TTF_Quit;
end;
{--------------------------------------------------------------------------}
procedure getTextSize(s:string;var w,h:word);
{This procedure supports textwidth and textheight functions}

var
    fontface        :   pointer;
    width           :   longint;
    height          :   longint;

begin
    openFont(fontface);
    s:=s+#0#0;
    TTF_SizeText(fontface,@s[1],width,height);
    w:=word(width);
    h:=word(height);
    closeFont(fontface);
end;
{--------------------------------------------------------------------------}
function textwidth(s:string)        :word;

var
    width       :   word;
    height      :   word;

begin
    getTextSize(s,width,height);
    textwidth:=width;
end;
{--------------------------------------------------------------------------}
function textheight(s:string)       :word;

var
    width       :   word;
    height      :   word;

begin
    getTextSize(s,width,height);
    textheight:=height;
end;
{--------------------------------------------------------------------------}
procedure cleardevice;
begin
    SDL_FillRect(screen,nil,SDL_MapRGB(screen^.format,r[bgcolor],g[bgcolor],b[bgcolor]));
    SDL_Flip(screen);
end;
{--------------------------------------------------------------------------}
procedure setfillstyle(pattern,color:word);
begin
    fillpattern:=pattern;
    fillcolor:=color;
end;
{--------------------------------------------------------------------------}
procedure line(x1,y1,x2,y2:smallint);
begin
    lineRGBA(screen,x1,y1,x2,y2,r[fgcolor],g[fgcolor],b[fgcolor],255);
    SDL_UpdateRect(screen,0,0,0,0);
end;
{--------------------------------------------------------------------------}
procedure bar(x1,y1,x2,y2:smallint);
begin
    boxRGBA(screen,x1,y1,x2,y2,r[fillcolor],g[fillcolor],b[fillcolor],255);
    SDL_UpdateRect(screen,0,0,0,0);
end;
{--------------------------------------------------------------------------}
procedure rectangle(x1,y1,x2,y2:smallint);
begin
    rectangleRGBA(screen,x1,y1,x2,y2,r[fgcolor],g[fgcolor],b[fgcolor],255);
    SDL_UpdateRect(screen,0,0,0,0);
end;
{--------------------------------------------------------------------------}
procedure fillellipse(x1,y1:smallint;xradius,yradius:word);
begin
    filledEllipseRGBA(screen,x1,y1,xradius,yradius,r[fillcolor],g[fillcolor],b[fillcolor],255);
    SDL_UpdateRect(screen,0,0,0,0);
end;
{--------------------------------------------------------------------------}
function getmaxx:smallint;
begin
    getmaxx:=screen^.w;
end;
{--------------------------------------------------------------------------}
function getmaxy:smallint;
begin
    getmaxy:=screen^.h;
end;
{--------------------------------------------------------------------------}
function keypressed         :   boolean;

begin
    SDL_PumpEvents;
    keypressed:=(SDL_PeepEvents(nil,1,SDL_PEEKEVENT,SDL_KEYDOWNMASK) >= 1);
end;
{--------------------------------------------------------------------------}
procedure delay(ms:word);

begin
    SDL_Delay(ms);
end;
{--------------------------------------------------------------------------}
function readarrowkey       :   char;
{Reads a lower ascii (7-bit) key, and translates arrow keys to numpad equivalents.}

var
    event       :   tSDL_Event;
    key         :   char;
    keyselected :   boolean;

begin
    SDL_EnableUnicode(SDL_Enable);
    key:=#0;
    keyselected:=false;
    repeat
        if(SDL_WaitEvent(@event) = 1) then
        begin
            if (event.type_ = SDL_KeyDown) then
            begin
                keyselected:=true;
                case event.key.keysym.sym of
                    SDLK_DOWN   :key:='2';
                    SDLK_LEFT   :key:='4';
                    SDLK_RIGHT  :key:='6';
                    SDLK_UP     :key:='8';
                else
                    key:=char(event.key.keysym.unicode);
                end;
            end;
            if (key = #0) then keyselected:=false;
        end;
    until(keyselected and (event.type_ = SDL_KeyUp));
    SDL_EnableUnicode(SDL_Disable);
    readarrowkey:=key;
end;
{--------------------------------------------------------------------------}
procedure outtextxy(x,y:word;s:string);

var
    fontface        :   pointer;
    fontcolor       :   tSDL_Color;
    fontcanvas      :   pSDL_Surface;
    destination     :   tSDL_Rect;

begin
    openFont(fontface);
    fontcolor.r:=r[getcolor];
    fontcolor.g:=g[getcolor];
    fontcolor.b:=b[getcolor];
    s:=s+#0#0;
    fontcanvas:=TTF_RenderText_Blended(fontface,@s[1],fontcolor);
    destination.x:=x;
    destination.y:=y;
    SDL_BlitSurface(fontcanvas,nil,screen,@destination);
    SDL_Flip(screen);
    SDL_FreeSurface(fontcanvas);
    closeFont(fontface);
end;
{--------------------------------------------------------------------------}
procedure prompt;

var
     origcolor      :    word;
     backgroundcolor:    word;
     x              :    word;
     y              :    word;
     ch             :    char;

begin
     x:=screen^.w - (textwidth('press a key to continue')+5);
     y:=screen^.h - (textheight('M')+5);
     origcolor:=getcolor;
     backgroundcolor:=getpixel(x,y);
     setcolor(white);
     outtextxy(x,y,'press a key to continue');
     ch:=readarrowkey;
     setcolor(backgroundcolor);
     outtextxy(x,y,'press a key to continue');
     setcolor(origcolor);
end;
{--------------------------------------------------------------------------}
procedure homecursor(var cursorx,cursory:integer);

{Sets x and y to the home position.}

begin
     cursorx:=xhome;
     cursory:=yhome;
end;
{--------------------------------------------------------------------------}
procedure centerwrite(x,y:integer;s:string);

begin
    outtextxy(x-(textwidth(s) DIV 2),y,s);
end;
{--------------------------------------------------------------------------}
procedure graphwrite(var x,y:integer;s:string);

begin
     outtextxy(x,y,s);
     x:=x + textwidth(s);
end;
{--------------------------------------------------------------------------}
procedure graphwriteln(var x,y:integer;s:string);

begin
    graphwrite(x,y,s);
    y:=y + textheight('M') + 2;
    x:=xhome;
end;
{--------------------------------------------------------------------------}
procedure graphread(var x,y:integer;var s:string);

var
     lastletter     :    integer;
     theletter      :    char;
     forecolor      :    word;
     ch             :    char;

begin
     forecolor:=getcolor;
     s:='';
     repeat
          ch:=readarrowkey;
          if(ch<>#13)then
               begin
                    if(ch<>#8)then
                         begin
                              s:=s + ch;
                              graphwrite(x,y,ch);
                         end
                    else
                         if(s<>'')then
                              begin
                                   lastletter:=length(s);
                                   theletter:=s[lastletter];
                                   delete(s,lastletter,1);
                                   x:=x - textwidth(theletter);
                                   setcolor(0);
                                   graphwrite(x,y,theletter);
                                   x:=x - textwidth(theletter);
                                   setcolor(forecolor);
                              end;
               end;
     until(ch=#13);
end;
{--------------------------------------------------------------------------}
procedure drawpicturebyline(beginx,beginy:integer;dosname:string);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of where the picture will be.}

var
    pasfile         :   text;
    x               :   word;
    y               :   word;
    color           :   word;
    length          :   word;
    lineoftext      :   string;
    errormsg        :   string;
    ch              :   char;

begin

    errormsg:='';
    if exist(dosname) then
    begin
        assign(pasfile,dosname);
        reset(pasfile);
        readln(pasfile,lineoftext);
        if  (lineoftext='FORMAT=LINE') then
        begin
            x:=beginx; {col}
            y:=beginy; {row}
            while not eof(pasfile) do
            begin
                while not eoln(pasfile) do
                begin
                    read(pasfile,color);
                    read(pasfile,ch);       {read the space in betwen}
                    read(pasfile,length);
                    if not eoln(pasfile) then read(pasfile,ch);
                    hlineRGBA(screen,x,x+length,y,r[color],g[color],b[color],255);
                    x:=x + length;
                end;
                readln(pasfile);
                y:=y + 1;
                x:=beginx;
            end;
            SDL_UpdateRect(screen, 0, 0, 0, 0);
        end
        else
            errormsg:=dosname+' wrong format';
        close(pasfile);
    end
    else
        errormsg:=dosname+' not found';

    if (errormsg <> '') then
    begin
        {Write the error to the screen}
        setcolor(lightblue);
        settextstyle(default,horizontal,1);
        outtextxy(beginx,beginy,errormsg);
    end;

end;

{--------------------------------------------------------------------------}
procedure writefile(beginy:integer;dosname:string);

{Puts the contents of a text file to the screen. Use beginy to start it
somewhere other than the very top.}

var
     pasfile        :    text;
     numlines       :    integer;
     lineoftext     :    string[100];
     x              :    integer;
     y              :    integer;
     doprompt       :    boolean;

begin
     x:=10;
     y:=beginy;
     doprompt:=false;
     numlines:=(screen^.h+1-y) DIV (textheight('M')+2) - 1;
     assign(pasfile,dosname);
     reset(pasfile);
     while not eof(pasfile) do
          begin
               readln(pasfile,lineoftext);
               doprompt:=(pos('{prompt}',lineoftext) = 1);
               if not(doprompt) then
               begin
                    graphwriteln(x,y,lineoftext);
                    numlines:=numlines - 1;
               end;
               doprompt:=( doprompt or (numlines=0));
               if doprompt then
               begin
                    prompt;
                    cleardevice;
                    homecursor(x,y);
                    numlines:=(screen^.h+1-y) DIV (textheight('M')+2) - 1;
               end;
          end;
     close(pasfile);
end;
{--------------------------------------------------------------------------}
procedure openscreen;
begin
    SDL_Init(SDL_INIT_VIDEO);
    screen:=SDL_SetVideoMode(displaywidth,displayheight,colordepth,SDL_SWSURFACE or SDL_RESIZABLE);
    if screen = nil then
    begin
        writeln('Error: couldn''t set video mode.');
        halt(1);
    end;
end;
{--------------------------------------------------------------------------}
procedure closescreen;
begin
	SDL_FreeSurface(screen);
    SDL_Quit;
end;
{-------------------------------------------------------------------------}
procedure init_palette;
{initializes the palette for backward compatibility}

type
    RGBRec = record
        Red     : byte;
        Green   : byte;
        Blue    : byte;
    end;

const
    { copied from freepascal packages/graph/src/inc/palette.inc }
    DefaultColors: Array[0..255] of RGBRec = (
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue: 168),
        (Red:   0;Green: 168;Blue:   0),
        (Red:   0;Green: 168;Blue: 168),
        (Red: 168;Green:   0;Blue:   0),
        (Red: 168;Green:   0;Blue: 168),
        (Red: 168;Green:  84;Blue:   0),
        (Red: 168;Green: 168;Blue: 168),
        (Red:  84;Green:  84;Blue:  84),
        (Red:  84;Green:  84;Blue: 252),
        (Red:  84;Green: 252;Blue:  84),
        (Red:  84;Green: 252;Blue: 252),
        (Red: 252;Green:  84;Blue:  84),
        (Red: 252;Green:  84;Blue: 252),
        (Red: 252;Green: 252;Blue:  84),
        (Red: 252;Green: 252;Blue: 252),
        (Red:   0;Green:   0;Blue:   0),
        (Red:  20;Green:  20;Blue:  20),
        (Red:  32;Green:  32;Blue:  32),
        (Red:  44;Green:  44;Blue:  44),
        (Red:  56;Green:  56;Blue:  56),
        (Red:  68;Green:  68;Blue:  68),
        (Red:  80;Green:  80;Blue:  80),
        (Red:  96;Green:  96;Blue:  96),
        (Red: 112;Green: 112;Blue: 112),
        (Red: 128;Green: 128;Blue: 128),
        (Red: 144;Green: 144;Blue: 144),
        (Red: 160;Green: 160;Blue: 160),
        (Red: 180;Green: 180;Blue: 180),
        (Red: 200;Green: 200;Blue: 200),
        (Red: 224;Green: 224;Blue: 224),
        (Red: 252;Green: 252;Blue: 252),
        (Red:   0;Green:   0;Blue: 252),
        (Red:  64;Green:   0;Blue: 252),
        (Red: 124;Green:   0;Blue: 252),
        (Red: 188;Green:   0;Blue: 252),
        (Red: 252;Green:   0;Blue: 252),
        (Red: 252;Green:   0;Blue: 188),
        (Red: 252;Green:   0;Blue: 124),
        (Red: 252;Green:   0;Blue:  64),
        (Red: 252;Green:   0;Blue:   0),
        (Red: 252;Green:  64;Blue:   0),
        (Red: 252;Green: 124;Blue:   0),
        (Red: 252;Green: 188;Blue:   0),
        (Red: 252;Green: 252;Blue:   0),
        (Red: 188;Green: 252;Blue:   0),
        (Red: 124;Green: 252;Blue:   0),
        (Red:  64;Green: 252;Blue:   0),
        (Red:   0;Green: 252;Blue:   0),
        (Red:   0;Green: 252;Blue:  64),
        (Red:   0;Green: 252;Blue: 124),
        (Red:   0;Green: 252;Blue: 188),
        (Red:   0;Green: 252;Blue: 252),
        (Red:   0;Green: 188;Blue: 252),
        (Red:   0;Green: 124;Blue: 252),
        (Red:   0;Green:  64;Blue: 252),
        (Red: 124;Green: 124;Blue: 252),
        (Red: 156;Green: 124;Blue: 252),
        (Red: 188;Green: 124;Blue: 252),
        (Red: 220;Green: 124;Blue: 252),
        (Red: 252;Green: 124;Blue: 252),
        (Red: 252;Green: 124;Blue: 220),
        (Red: 252;Green: 124;Blue: 188),
        (Red: 252;Green: 124;Blue: 156),
        (Red: 252;Green: 124;Blue: 124),
        (Red: 252;Green: 156;Blue: 124),
        (Red: 252;Green: 188;Blue: 124),
        (Red: 252;Green: 220;Blue: 124),
        (Red: 252;Green: 252;Blue: 124),
        (Red: 220;Green: 252;Blue: 124),
        (Red: 188;Green: 252;Blue: 124),
        (Red: 156;Green: 252;Blue: 124),
        (Red: 124;Green: 252;Blue: 124),
        (Red: 124;Green: 252;Blue: 156),
        (Red: 124;Green: 252;Blue: 188),
        (Red: 124;Green: 252;Blue: 220),
        (Red: 124;Green: 252;Blue: 252),
        (Red: 124;Green: 220;Blue: 252),
        (Red: 124;Green: 188;Blue: 252),
        (Red: 124;Green: 156;Blue: 252),
        (Red: 180;Green: 180;Blue: 252),
        (Red: 196;Green: 180;Blue: 252),
        (Red: 216;Green: 180;Blue: 252),
        (Red: 232;Green: 180;Blue: 252),
        (Red: 252;Green: 180;Blue: 252),
        (Red: 252;Green: 180;Blue: 232),
        (Red: 252;Green: 180;Blue: 216),
        (Red: 252;Green: 180;Blue: 196),
        (Red: 252;Green: 180;Blue: 180),
        (Red: 252;Green: 196;Blue: 180),
        (Red: 252;Green: 216;Blue: 180),
        (Red: 252;Green: 232;Blue: 180),
        (Red: 252;Green: 252;Blue: 180),
        (Red: 232;Green: 252;Blue: 180),
        (Red: 216;Green: 252;Blue: 180),
        (Red: 196;Green: 252;Blue: 180),
        (Red: 180;Green: 252;Blue: 180),
        (Red: 180;Green: 252;Blue: 196),
        (Red: 180;Green: 252;Blue: 216),
        (Red: 180;Green: 252;Blue: 232),
        (Red: 180;Green: 252;Blue: 252),
        (Red: 180;Green: 232;Blue: 252),
        (Red: 180;Green: 216;Blue: 252),
        (Red: 180;Green: 196;Blue: 252),
        (Red:   0;Green:   0;Blue: 112),
        (Red:  28;Green:   0;Blue: 112),
        (Red:  56;Green:   0;Blue: 112),
        (Red:  84;Green:   0;Blue: 112),
        (Red: 112;Green:   0;Blue: 112),
        (Red: 112;Green:   0;Blue:  84),
        (Red: 112;Green:   0;Blue:  56),
        (Red: 112;Green:   0;Blue:  28),
        (Red: 112;Green:   0;Blue:   0),
        (Red: 112;Green:  28;Blue:   0),
        (Red: 112;Green:  56;Blue:   0),
        (Red: 112;Green:  84;Blue:   0),
        (Red: 112;Green: 112;Blue:   0),
        (Red:  84;Green: 112;Blue:   0),
        (Red:  56;Green: 112;Blue:   0),
        (Red:  28;Green: 112;Blue:   0),
        (Red:   0;Green: 112;Blue:   0),
        (Red:   0;Green: 112;Blue:  28),
        (Red:   0;Green: 112;Blue:  56),
        (Red:   0;Green: 112;Blue:  84),
        (Red:   0;Green: 112;Blue: 112),
        (Red:   0;Green:  84;Blue: 112),
        (Red:   0;Green:  56;Blue: 112),
        (Red:   0;Green:  28;Blue: 112),
        (Red:  56;Green:  56;Blue: 112),
        (Red:  68;Green:  56;Blue: 112),
        (Red:  84;Green:  56;Blue: 112),
        (Red:  96;Green:  56;Blue: 112),
        (Red: 112;Green:  56;Blue: 112),
        (Red: 112;Green:  56;Blue:  96),
        (Red: 112;Green:  56;Blue:  84),
        (Red: 112;Green:  56;Blue:  68),
        (Red: 112;Green:  56;Blue:  56),
        (Red: 112;Green:  68;Blue:  56),
        (Red: 112;Green:  84;Blue:  56),
        (Red: 112;Green:  96;Blue:  56),
        (Red: 112;Green: 112;Blue:  56),
        (Red:  96;Green: 112;Blue:  56),
        (Red:  84;Green: 112;Blue:  56),
        (Red:  68;Green: 112;Blue:  56),
        (Red:  56;Green: 112;Blue:  56),
        (Red:  56;Green: 112;Blue:  68),
        (Red:  56;Green: 112;Blue:  84),
        (Red:  56;Green: 112;Blue:  96),
        (Red:  56;Green: 112;Blue: 112),
        (Red:  56;Green:  96;Blue: 112),
        (Red:  56;Green:  84;Blue: 112),
        (Red:  56;Green:  68;Blue: 112),
        (Red:  80;Green:  80;Blue: 112),
        (Red:  88;Green:  80;Blue: 112),
        (Red:  96;Green:  80;Blue: 112),
        (Red: 104;Green:  80;Blue: 112),
        (Red: 112;Green:  80;Blue: 112),
        (Red: 112;Green:  80;Blue: 104),
        (Red: 112;Green:  80;Blue:  96),
        (Red: 112;Green:  80;Blue:  88),
        (Red: 112;Green:  80;Blue:  80),
        (Red: 112;Green:  88;Blue:  80),
        (Red: 112;Green:  96;Blue:  80),
        (Red: 112;Green: 104;Blue:  80),
        (Red: 112;Green: 112;Blue:  80),
        (Red: 104;Green: 112;Blue:  80),
        (Red:  96;Green: 112;Blue:  80),
        (Red:  88;Green: 112;Blue:  80),
        (Red:  80;Green: 112;Blue:  80),
        (Red:  80;Green: 112;Blue:  88),
        (Red:  80;Green: 112;Blue:  96),
        (Red:  80;Green: 112;Blue: 104),
        (Red:  80;Green: 112;Blue: 112),
        (Red:  80;Green: 104;Blue: 112),
        (Red:  80;Green:  96;Blue: 112),
        (Red:  80;Green:  88;Blue: 112),
        (Red:   0;Green:   0;Blue:  64),
        (Red:  16;Green:   0;Blue:  64),
        (Red:  32;Green:   0;Blue:  64),
        (Red:  48;Green:   0;Blue:  64),
        (Red:  64;Green:   0;Blue:  64),
        (Red:  64;Green:   0;Blue:  48),
        (Red:  64;Green:   0;Blue:  32),
        (Red:  64;Green:   0;Blue:  16),
        (Red:  64;Green:   0;Blue:   0),
        (Red:  64;Green:  16;Blue:   0),
        (Red:  64;Green:  32;Blue:   0),
        (Red:  64;Green:  48;Blue:   0),
        (Red:  64;Green:  64;Blue:   0),
        (Red:  48;Green:  64;Blue:   0),
        (Red:  32;Green:  64;Blue:   0),
        (Red:  16;Green:  64;Blue:   0),
        (Red:   0;Green:  64;Blue:   0),
        (Red:   0;Green:  64;Blue:  16),
        (Red:   0;Green:  64;Blue:  32),
        (Red:   0;Green:  64;Blue:  48),
        (Red:   0;Green:  64;Blue:  64),
        (Red:   0;Green:  48;Blue:  64),
        (Red:   0;Green:  32;Blue:  64),
        (Red:   0;Green:  16;Blue:  64),
        (Red:  32;Green:  32;Blue:  64),
        (Red:  40;Green:  32;Blue:  64),
        (Red:  48;Green:  32;Blue:  64),
        (Red:  56;Green:  32;Blue:  64),
        (Red:  64;Green:  32;Blue:  64),
        (Red:  64;Green:  32;Blue:  56),
        (Red:  64;Green:  32;Blue:  48),
        (Red:  64;Green:  32;Blue:  40),
        (Red:  64;Green:  32;Blue:  32),
        (Red:  64;Green:  40;Blue:  32),
        (Red:  64;Green:  48;Blue:  32),
        (Red:  64;Green:  56;Blue:  32),
        (Red:  64;Green:  64;Blue:  32),
        (Red:  56;Green:  64;Blue:  32),
        (Red:  48;Green:  64;Blue:  32),
        (Red:  40;Green:  64;Blue:  32),
        (Red:  32;Green:  64;Blue:  32),
        (Red:  32;Green:  64;Blue:  40),
        (Red:  32;Green:  64;Blue:  48),
        (Red:  32;Green:  64;Blue:  56),
        (Red:  32;Green:  64;Blue:  64),
        (Red:  32;Green:  56;Blue:  64),
        (Red:  32;Green:  48;Blue:  64),
        (Red:  32;Green:  40;Blue:  64),
        (Red:  44;Green:  44;Blue:  64),
        (Red:  48;Green:  44;Blue:  64),
        (Red:  52;Green:  44;Blue:  64),
        (Red:  60;Green:  44;Blue:  64),
        (Red:  64;Green:  44;Blue:  64),
        (Red:  64;Green:  44;Blue:  60),
        (Red:  64;Green:  44;Blue:  52),
        (Red:  64;Green:  44;Blue:  48),
        (Red:  64;Green:  44;Blue:  44),
        (Red:  64;Green:  48;Blue:  44),
        (Red:  64;Green:  52;Blue:  44),
        (Red:  64;Green:  60;Blue:  44),
        (Red:  64;Green:  64;Blue:  44),
        (Red:  60;Green:  64;Blue:  44),
        (Red:  52;Green:  64;Blue:  44),
        (Red:  48;Green:  64;Blue:  44),
        (Red:  44;Green:  64;Blue:  44),
        (Red:  44;Green:  64;Blue:  48),
        (Red:  44;Green:  64;Blue:  52),
        (Red:  44;Green:  64;Blue:  60),
        (Red:  44;Green:  64;Blue:  64),
        (Red:  44;Green:  60;Blue:  64),
        (Red:  44;Green:  52;Blue:  64),
        (Red:  44;Green:  48;Blue:  64),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0),
        (Red:   0;Green:   0;Blue:   0));

var
    loop    :   byte;

begin
    for loop:= black to white do
    begin
        r[loop]:=DefaultColors[loop].Red;
        g[loop]:=DefaultColors[loop].Green;
        b[loop]:=DefaultColors[loop].Blue;
    end;
end;
{===========================================================================}

Begin {main}

    init_palette;
    fgcolor:=white;
    bgcolor:=black;
    textfont:=default;
    textdirection:=default;
    textsize:=default;
    fontpath:='fonts';

End.  {main}
