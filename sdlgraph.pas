{
   SDLgraph - GRAPH unit implentation using SDL
   Copyright (C) 2005 Angelo Bertolli
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
  
   Angelo Bertolli
   angelo.bertolli@gmail.com
   http://sdlgraph.sourceforge.net/
}

{
   This unit requires SDL4Freepascal which in turn requires the SDL
   run-time libraries.
   SDL4Freepascal: http://sdl4fp.sourceforge.net/
   SDL: http://www.libsdl.org/
}

Unit sdlgraph;

INTERFACE

Uses SDL, SDL_Video, crt;

{ Public things and function prototypes }


Const

   SDLgraph_version = '0.1';


{ Constants for mode selection }

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

Type
   sdlgraph_t     =  record
                        colordepth: byte;
                        height: word;
                        width: word;
                     end;

Var
   sdlgraph_env   :  sdlgraph_t;


IMPLEMENTATION

{ Functions }

Begin

{ Initialization }

   with sdlgraph_env do
      begin
         colordepth:=0;
         height:=0;
         width:=0;
      end;

End.
