{Angelo Bertolli}

program SDLBMPViewer;

{This attempts to view native MS Paint 4-bit BMP files without
 changing the palette.}

uses SDL, SDL_Video, crt;

const
   width = 640 ;
   height = 480 ;
   colordepth = 16 ;
black=0;
blue=1;
green=2;
cyan=3;
red=4;
magenta=5;
brown=6;
lightgray=7;
darkgray=8;
lightblue=9;
lightgreen=10;
lightcyan=11;
lightred=12;
lightmagenta=13;
yellow=14;
white=15;

type
   Pixel = Word ; { Must have colordepth bits }
   TpixelBuf = Array [0..height-1, 0..width-1] of Pixel ;

var
   device    :     integer;
   mode      :     integer;
   ch        :     char;
   bmpfile   :     string;
   screen    :     PSDL_Surface ;

{--------------------------------------------------------------------------}
function readjust(c:Pixel):Pixel;

var
   r         :     byte;
   g         :     byte;
   b         :     byte;

begin

   r:=128;
   g:=128;
   b:=128;

   case c of
      lightgray     :begin
                        r:=190;
                        g:=190;
                        b:=190;
                     end;
      darkgray      :begin
                        r:=90;
                        g:=90;
                        b:=90;
                     end;
      blue          :begin
                        r:=0;
                        g:=0;
                        b:=200;
                     end;
      lightblue     :begin
                        r:=90;
                        g:=90;
                        b:=255;
                     end;
      cyan          :begin
                        r:=0;
                        g:=190;
                        b:=190;
                     end;
      lightcyan     :begin
                        r:=0;
                        g:=255;
                        b:=255;
                     end;
      brown         :begin
                        r:=190;
                        g:=80;
                        b:=64;
                     end;
      yellow        :begin
                        r:=255;
                        g:=255;
                        b:=0;
                     end;
      red           :begin
                        r:=200;
                        g:=0;
                        b:=0;
                     end;
      lightred      :begin
                        r:=255;
                        g:=90;
                        b:=90;
                     end;
      white         :begin
                        r:=255;
                        g:=255;
                        b:=255;
                     end;
      black         :begin
                        r:=0;
                        g:=0;
                        b:=0;
                     end;
      magenta       :begin
                        r:=150;
                        g:=0;
                        b:=150;
                     end;
      lightmagenta  :begin
                        r:=255;
                        g:=0;
                        b:=255;
                     end;
      green         :begin
                        r:=0;
                        g:=190;
                        b:=0;
                     end;
      lightgreen    :begin
                        r:=0;
                        g:=255;
                        b:=0;
                     end;
   end; {case}

   r:=trunc((r/255)*31);
   g:=trunc((g/255)*63);
   b:=trunc((b/255)*31);

   readjust:=(r shl 11) + (g shl 5) + b;

end;
{--------------------------------------------------------------------------}
procedure drawbmp16(dosname:string;xpos,ypos:integer);

type
     FileHeader    = record
                        bfType        : word;
                        bfSize        : longint;
                        bfReserved1   : word;
                        bfReserved2   : word;
                        bfOffBits     : longint;
     end;

     InfoHeader = record
                     biSize           : longint;
                     biWidth          : longint;
                     biHeight         : longint;
                     biPlanes         : word;
                     biBitCount       : word;
                     biCompression    : longint;
                     biSizeImage      : longint;
                     biXPelsPerMeter  : longint;
                     biYPelsPerMeter  : longint;
                     biClrUsed        : longint;
                     biClrImportant   : longint;
     end;

     Quad = record
               blue                   : byte;
               green                  : byte;
               red                    : byte;
               Reserved               : byte;
     end;

     TBitmapInfo = record
                      bmiFileheader   : FileHeader;
                      bmiHeader       : InfoHeader;
                      bmiColors       : array[0..15] of Quad;
     end;

var
     f     :     file of byte;
     info  :     file of TbitmapInfo;
     data  :     TbitmapInfo;
     color :     Pixel;
     b     :     byte;
     x     :     word;
     y     :     word;

begin

     assign(info,dosname);
     reset(info);
     read(info,data);
     close(info);

     assign(f,dosname);
     reset(f);
     seek(f,data.bmifileheader.bfoffbits);

     for y:=data.bmiheader.biheight downto 1 do
          for x:=1 to (data.bmiheader.biwidth div 2+3) and not 3  do
               begin
                    read(f,b);
                    color:=b shr 4;
                    Tpixelbuf(screen^.pixels^)[y+ypos,(x*2)+xpos] := readjust(color);
                    color:=b and 15;
                    Tpixelbuf(screen^.pixels^)[y+ypos,(x*2)+1+xpos] := readjust(color);
               end;

     close(f);

end;
{--------------------------------------------------------------------------}

begin
          clrscr;
          write('4-bit BMP file:  ');
          readln(bmpfile);

          SDL_Init(SDL_INIT_VIDEO);
          screen:=SDL_SetVideoMode(width,height,colordepth,SDL_SWSURFACE);

          drawbmp16(bmpfile,0,0);

          SDL_UpdateRect(screen, 0, 0, width, height);

          ch:=readkey;
          SDL_FreeSurface(screen) ;
          SDL_Quit
end.

{
MS Paint -> Pascal

black          -> black
white          -> white
dark gray      -> light gray
light gray     -> dark gray
red            -> blue
light red      -> light blue
dark yellow    -> cyan
yellow         -> light cyan
green          -> green
light green    -> light green
cyan           -> brown
light cyan     -> yellow
blue           -> red
light blue     -> light red
magenta        -> magenta
light magenta  -> light magenta

}
