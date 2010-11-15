{
SDLGraph Unit
Copyright (C) 2010 Angelo Bertolli

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

Unit SDLGraph;

INTERFACE

uses sdl, sdl_ttf;

const
	{unit version}
	version		= '0.1';

	{16 color definitions}
	black		= 0;
	blue		= 1;
	green		= 2;
	cyan		= 3;
	red		= 4;
	magenta		= 5;
	brown		= 6;
	lightgray	= 7;
	darkgray	= 8;
	lightblue	= 9;
	lightgreen	= 10;
	lightcyan	= 11;
	lightred	= 12;
	lightmagenta	= 13;
	yellow		= 14;
	white		= 15;

	maxcolors	= 16;

	{fill patterns}
	emptyfill	= 0;
	solidfill	= 1;
	linefill	= 2;
	ltslashfill	= 3;
	slashfill	= 4;
	bkslashfill	= 5;
	ltbkslashfill	= 6;
	hatchfill	= 7;
	xhatchfill	= 8;
	interleavefill	= 9;
	widedotfill	= 10;
	closedotfill	= 11;
	userfill	= 12;

	{used for graphics text}
	default		= 0;
	triplex		= 1;
	small		= 2;
	sanseri		= 3;
	gothic		= 4;
	horizontal	= 0;
	vertical	= 1;

type
	PaletteType	= record
		size	: word;
		color	: array[0..maxcolors-1] of TSDL_Color;
	end;

procedure cleardevice;
procedure outtextxy(x,y:integer;s:string);
procedure setcolor(c:word);
procedure settextstyle(face,direction,size:byte);

IMPLEMENTATION

var
	graph_env	: record
		screenw		: word;
		screenh		: word;
		depth		: byte;
		color		: word;
		bkcolor		: word;
		cursorx		: word;
		cursory		: word;
		fontface	: byte;
		fontdirection	: byte;
		fontsize	: byte;
		driverpath	: string;
		palette		: palettetype;
	end;

	screen		: PSDL_Surface;

{Include helper (non-interface) functions.}
{$I sdlgraphx.pas}
{--------------------------------------------------------------------------}
procedure cleardevice;
{Clears the graphical screen (with the current background color)}
begin
	with graph_env.palette.color[graph_env.bkcolor] do
	begin
		SDL_FillRect(screen,nil,SDL_MapRGB(SDL_GetVideoSurface^.format,r,g,b));
		SDL_Flip(screen);
	end;
	with graph_env do
	begin
		cursorx:=0;
		cursory:=0;
	end;
end;
{--------------------------------------------------------------------------}
function getcolor:word;
begin
	getcolor:=graph_env.color;
end;
{--------------------------------------------------------------------------}
procedure setcolor(c:word);
begin
	graph_env.color:=c;
end;
{--------------------------------------------------------------------------}
function getbkcolor:word;
begin
	getbkcolor:=graph_env.bkcolor;
end;
{--------------------------------------------------------------------------}
procedure setbkcolor(c:word);
begin
	graph_env.bkcolor:=c;
end;
{--------------------------------------------------------------------------}
function getmaxx:smallint;
begin
	getmaxx:=graph_env.screenw;
end;
{--------------------------------------------------------------------------}
function getmaxy:smallint;
begin
	getmaxy:=graph_env.screenh;
end;
{--------------------------------------------------------------------------}
procedure settextstyle(face,direction,size:byte);
begin
	with graph_env do
	begin
		fontface:=face;
		fontdirection:=direction;
		fontsize:=size;
	end;
end;
{-------------------------------------------------------------------------}
function getpixel(x,y:word):word;
{Get pixel color}

begin
	getpixel:=0; {screen^.pixels^[y,x]; -- needs to be converted to pascal colors}
end;
{-------------------------------------------------------------------------}
procedure putpixel(x,y,c:word);
{Places a pixel of color on the screen}

begin

end;
{-------------------------------------------------------------------------}
procedure outtextxy(x,y:integer;s:string);
var
	font		: pointer;
	fontcolor	: TSDL_Color;
	sdltext		: PSDL_Surface;
	dest		: PSDL_Rect;
begin
	fontcolor:=graph_env.palette.color[graph_env.color];
	font:=TTF_OpenFont(getsdlfontface(),getsdlfontsize());
	{render function wants a C-style string}
	s:=s+#0;
	sdltext:=TTF_RenderText_Solid(font,@s[1],fontcolor);
	new(dest);
	dest^.x:=x;
	dest^.y:=y;
	{
	dest^.w:=0;
	dest^.h:=0;
	}
	SDL_BlitSurface(sdltext,NIL,screen,dest);
	SDL_Flip(screen);
	TTF_CloseFont(font);
end;
{-------------------------------------------------------------------------}
function textwidth(s:string):word;
{Returns width of string in pixels.}
var
	loop	: integer;
	font	: pointer;
	size	: word;
	adv,minx,maxx,miny,maxy:longint;
begin
	font:=TTF_OpenFont(getsdlfontface,getsdlfontsize);
	size:=0;
	adv:=0;
	for loop:=1 to length(s) do
	begin
		TTF_GlyphMetrics(font,ord(s[loop]),minx,maxx,miny,maxy,adv);
		size:=size + adv;
	end;
	textwidth:=size;
end;
{-------------------------------------------------------------------------}
function textheight(s:string):word;
{Returns width of a string in pixels.}

var
	loop	: integer;
	font	: pointer;
	size	: word;
	adv,minx,maxx,miny,maxy:longint;

begin
	font:=TTF_OpenFont(getsdlfontface,getsdlfontsize);
	size:=0;
	for loop:=1 to length(s) do
	begin
		TTF_GlyphMetrics(font,ord(s[loop]),minx,maxx,miny,maxy,adv);
		if (size < maxy) then size:=maxy;
	end;
	textheight:=size;
end;
{--------------------------------------------------------------------------}
procedure initgraph(var driver,mode:smallint;const path:string);

var
	loop	: integer;

begin
	{Initialize all variables.  Right now we enforce one mode only.}
	with graph_env do
	begin
		driverpath:=path;
		screenw:=640;
		screenh:=480;
		depth:=4;
		color:=white;
		bkcolor:=black;
		cursorx:=0;
		cursory:=0;
		fontface:=default;
		fontdirection:=horizontal;
		fontsize:=2;
		{ Set up the colors for the 4-bit palette }
		palette.size:=16;
		for loop:=0 to palette.size-1 do
		with palette.color[loop] do
		        case loop of
		        black           :begin r:=0;    g:=0;   b:=0;   end;
		        blue            :begin r:=0;    g:=0;   b:=200; end;
		        green           :begin r:=0;    g:=190; b:=0;   end;
		        cyan            :begin r:=0;    g:=190; b:=190; end;
		        red             :begin r:=200;  g:=0;   b:=0;   end;
		        magenta         :begin r:=150;  g:=0;   b:=150; end;
		        brown           :begin r:=190;  g:=80;  b:=64;  end;
       			lightgray       :begin r:=190;  g:=190; b:=190; end;
		        darkgray        :begin r:=90;   g:=90;  b:=90;  end;
		        lightblue       :begin r:=90;   g:=90;  b:=255; end;
		        lightgreen      :begin r:=0;    g:=255; b:=0;   end;
		        lightcyan       :begin r:=0;    g:=255; b:=255; end;
		        lightred        :begin r:=255;  g:=90;  b:=90;  end;
		        lightmagenta    :begin r:=255;  g:=0;   b:=255; end;
		        yellow          :begin r:=255;  g:=255; b:=0;   end;
		        white           :begin r:=255;  g:=255; b:=255; end;
		        end; {case}
	end; {graph_env}

	{ Use variables to start screen }
	with graph_env do
	begin
		screen:=SDL_SetVideoMode(screenw,screenh,depth,SDL_HWPALETTE);
		if (screen=nil) then
		begin
			{ do some kind of error handling or setting here}
			halt();
		end;
	end;

end;
{--------------------------------------------------------------------------}
begin {main}
end.  {main}
