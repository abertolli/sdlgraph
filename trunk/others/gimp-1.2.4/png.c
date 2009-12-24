/*
 * "$Id: png.c,v 1.61.2.8 2003/04/12 15:19:06 bolsh Exp $"
 *
 *   Portable Network Graphics (PNG) plug-in for The GIMP -- an image
 *   manipulation program
 *
 *   Copyright 1997-1998 Michael Sweet (mike@easysw.com) and
 *   Daniel Skarda (0rfelyus@atrey.karlin.mff.cuni.cz).
 *   and 1999-2000 Nick Lamb (njl195@zepler.org.uk)
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * Contents:
 *
 *   main()                      - Main entry - just call gimp_main()...
 *   query()                     - Respond to a plug-in query...
 *   run()                       - Run the plug-in...
 *   load_image()                - Load a PNG image into a new image window.
 *   respin_cmap()               - Re-order a Gimp colormap for PNG tRNS
 *   save_image()                - Save the specified image to a PNG file.
 *   save_ok_callback()          - Destroy the save dialog and save the image.
 *   save_compression_callback() - Update the image compression level.
 *   save_interlace_update()     - Update the interlacing option.
 *   save_dialog()               - Pop up the save dialog.
 *
 * Revision History:
 *
 *   see ChangeLog
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include <gtk/gtk.h>

#include <libgimp/gimp.h>
#include <libgimp/gimpui.h>

#include <png.h>                /* PNG library definitions */

#include "libgimp/stdplugins-intl.h"


/*
 * Constants...
 */

#define PLUG_IN_VERSION  "1.3.4 - 03 September 2002"
#define SCALE_WIDTH      125

#define DEFAULT_GAMMA    2.20

/*
 * Structures...
 */

typedef struct
{
  gint  interlaced;
  gint  compression_level;
  gint  bkgd;
  gint  gama;
  gint  offs;
  gint  phys;
  gint  time;
} PngSaveVals;


/*
 * Local functions...
 */

static void     query                     (void);
static void     run                       (gchar   *name,
                                           gint     nparams,
                                           GimpParam  *param,
                                           gint    *nreturn_vals,
                                           GimpParam **return_vals);

static gint32   load_image                (gchar   *filename);
static gint     save_image                (gchar   *filename,
                                           gint32   image_ID,
                                           gint32   drawable_ID,
                                           gint32   orig_image_ID);

static void     respin_cmap               (png_structp   pp,
                                           png_infop     info,
                                           guchar       *remap,
                                           gint32        image_ID,
                                           GimpDrawable *drawable);

static gint     save_dialog               (void);
static void     save_ok_callback          (GtkWidget     *widget,
                                           gpointer       data);

static int find_unused_ia_colour          (guchar *pixels,
                                           int numpixels,
                                           int* colors);

/*
 * Globals...
 */

GimpPlugInInfo PLUG_IN_INFO =
{
  NULL,  /* init_proc  */
  NULL,  /* quit_proc  */
  query, /* query_proc */
  run,   /* run_proc   */
};

PngSaveVals pngvals = 
{
  FALSE,
  6,
  TRUE, FALSE, FALSE, TRUE, TRUE
};

static gboolean runme = FALSE;

/*
 * 'main()' - Main entry - just call gimp_main()...
 */

MAIN()

/* Try to find a colour in the palette which isn't actually 
 * used in the image, so that we can use it as the transparency 
 * index. Taken from gif.c */
  
static int find_unused_ia_colour (guchar *pixels,
                                  int numpixels,
                                  int *colors)
{
  int i;
  gboolean ix_used[256];
  gboolean trans_used = FALSE;

  for (i = 0; i < *colors; i++)
    {
      ix_used[i] = FALSE;
    }

  for (i = 0; i < numpixels; i++)
    {
      /* If there is no alpha, then the index associated with 
       * this pixel is taken */
      if (pixels[i*2 + 1] > 128) 
        ix_used[pixels[i*2]] = TRUE;
      else
        {
          trans_used = TRUE;
        }
    }
  
  // If there is no transparency, ignore alpha.
  if (trans_used == FALSE)
    return -1;

  for (i = 0; i < *colors; i++)
    {
      if (ix_used[i] == FALSE)
        {
          return i;
        }
    }

  /* Couldn't find an unused colour index within the number of
     bits per pixel we wanted.  Will have to increment the number
     of colours in the image and assign a transparent pixel there. */
  if ((*colors) < 256)
    {
      (*colors)++;
      return ((*colors)-1);
    }
  
  g_message (_("PNG: Couldn't simply reduce colors further.\nSaving as opaque.\n"));
  return (-1);
}

/*
 * 'query()' - Respond to a plug-in query...
 */

static void
query (void)
{
  static GimpParamDef load_args[] =
  {
    { GIMP_PDB_INT32,      "run_mode",     "Interactive, non-interactive" },
    { GIMP_PDB_STRING,     "filename",     "The name of the file to load" },
    { GIMP_PDB_STRING,     "raw_filename", "The name of the file to load" }
  };
  static GimpParamDef load_return_vals[] =
  {
    { GIMP_PDB_IMAGE,      "image",        "Output image" }
  };
  static gint nload_args = sizeof (load_args) / sizeof (load_args[0]);
  static gint nload_return_vals = (sizeof (load_return_vals) /
                                   sizeof (load_return_vals[0]));

  static GimpParamDef   save_args[] =
  {
    { GIMP_PDB_INT32,   "run_mode",     "Interactive, non-interactive" },
    { GIMP_PDB_IMAGE,   "image",        "Input image" },
    { GIMP_PDB_DRAWABLE,        "drawable",     "Drawable to save" },
    { GIMP_PDB_STRING,  "filename",     "The name of the file to save the image in" },
    { GIMP_PDB_STRING,  "raw_filename", "The name of the file to save the image in" },
    { GIMP_PDB_INT32,   "interlace",    "Use Adam7 interlacing?" },
    { GIMP_PDB_INT32,   "compression",  "Deflate Compression factor (0--9)" },
    { GIMP_PDB_INT32,   "bkgd",         "Write bKGD chunk?" },
    { GIMP_PDB_INT32,   "gama",         "Write gAMA chunk?" },
    { GIMP_PDB_INT32,   "offs",         "Write oFFs chunk?" },
    { GIMP_PDB_INT32,   "phys",         "Write tIME chunk?" },
    { GIMP_PDB_INT32,   "time",         "Write pHYs chunk?" }
  };
  static gint nsave_args = sizeof (save_args) / sizeof (save_args[0]);

  gimp_install_procedure ("file_png_load",
                          "Loads files in PNG file format",
                          "This plug-in loads Portable Network Graphics (PNG) files.",
                          "Michael Sweet <mike@easysw.com>, Daniel Skarda <0rfelyus@atrey.karlin.mff.cuni.cz>",
                          "Michael Sweet <mike@easysw.com>, Daniel Skarda <0rfelyus@atrey.karlin.mff.cuni.cz>, Nick Lamb <njl195@zepler.org.uk>",
                          PLUG_IN_VERSION,
                          "<Load>/PNG",
                          NULL,
                          GIMP_PLUGIN,
                          nload_args, nload_return_vals,
                          load_args, load_return_vals);

  gimp_install_procedure  ("file_png_save",
                           "Saves files in PNG file format",
                           "This plug-in saves Portable Network Graphics (PNG) files.",
                           "Michael Sweet <mike@easysw.com>, Daniel Skarda <0rfelyus@atrey.karlin.mff.cuni.cz>",
                           "Michael Sweet <mike@easysw.com>, Daniel Skarda <0rfelyus@atrey.karlin.mff.cuni.cz>, Nick Lamb <njl195@zepler.org.uk>",
                           PLUG_IN_VERSION,
                           "<Save>/PNG",
                           "RGB*,GRAY*,INDEXED*",
                           GIMP_PLUGIN,
                           nsave_args, 0,
                           save_args, NULL);

  gimp_register_magic_load_handler ("file_png_load",
                                    "png",
                                    "",
                                    "0,string,\211PNG\r\n\032\n");
  gimp_register_save_handler       ("file_png_save",
                                    "png",
                                    "");
}


/*
 * 'run()' - Run the plug-in...
 */

static void
run (gchar   *name,
     gint     nparams,
     GimpParam  *param,
     gint    *nreturn_vals,
     GimpParam **return_vals)
{
  static GimpParam values[2];
  GimpRunModeType  run_mode;
  GimpPDBStatusType   status = GIMP_PDB_SUCCESS;
  gint32        image_ID;
  gint32        drawable_ID;
  gint32        orig_image_ID;
  GimpExportReturnType export = GIMP_EXPORT_CANCEL;

  *nreturn_vals = 1;
  *return_vals  = values;
  values[0].type          = GIMP_PDB_STATUS;
  values[0].data.d_status = GIMP_PDB_EXECUTION_ERROR;

  if (strcmp (name, "file_png_load") == 0)
    {
      INIT_I18N_UI ();
      image_ID = load_image (param[1].data.d_string);

      if (image_ID != -1)
        {
          *nreturn_vals = 2;
          values[1].type         = GIMP_PDB_IMAGE;
          values[1].data.d_image = image_ID;
        }
      else
        {
          status = GIMP_PDB_EXECUTION_ERROR;
        }
    }
  else if (strcmp (name, "file_png_save") == 0)
    {
      INIT_I18N_UI();

      run_mode = param[0].data.d_int32;
      image_ID = orig_image_ID = param[1].data.d_int32;
      drawable_ID = param[2].data.d_int32;
    
      /*  eventually export the image */ 
      switch (run_mode)
        {
        case GIMP_RUN_INTERACTIVE:
        case GIMP_RUN_WITH_LAST_VALS:
          gimp_ui_init ("png", FALSE);
          export = gimp_export_image (&image_ID, &drawable_ID, "PNG", 
                                      (GIMP_EXPORT_CAN_HANDLE_RGB |
                                       GIMP_EXPORT_CAN_HANDLE_GRAY |
                                       GIMP_EXPORT_CAN_HANDLE_INDEXED |
                                       GIMP_EXPORT_CAN_HANDLE_ALPHA ));
          if (export == GIMP_EXPORT_CANCEL)
            {
              *nreturn_vals = 1;
              values[0].data.d_status = GIMP_PDB_CANCEL;
              return;
            }
          break;
        default:
          break;
        }

      switch (run_mode)
        {
        case GIMP_RUN_INTERACTIVE:
          /*
           * Possibly retrieve data...
           */
          gimp_get_data ("file_png_save", &pngvals);

	  /*
	   * If the image has no transparency, then there is usually
	   * no need to save a bKGD chunk.  For more information, see:
	   * http://bugzilla.gnome.org/show_bug.cgi?id=92395
	   */
	  if (! gimp_drawable_has_alpha (drawable_ID))
	    pngvals.bkgd = FALSE;

          /*
           * Then acquire information with a dialog...
           */
          if (!save_dialog())
            status = GIMP_PDB_CANCEL;
          break;

        case GIMP_RUN_NONINTERACTIVE:
          /*
           * Make sure all the arguments are there!
           */
          if (nparams != 12)
            {
              status = GIMP_PDB_CALLING_ERROR;
            }
          else
            {
              pngvals.interlaced        = param[5].data.d_int32;
              pngvals.compression_level = param[6].data.d_int32;
              pngvals.bkgd              = param[7].data.d_int32;
              pngvals.gama              = param[8].data.d_int32;
              pngvals.phys              = param[9].data.d_int32;
              pngvals.offs              = param[10].data.d_int32;
              pngvals.time              = param[11].data.d_int32;

              if (pngvals.compression_level < 0 ||
                  pngvals.compression_level > 9)
                status = GIMP_PDB_CALLING_ERROR;
            };
          break;

        case GIMP_RUN_WITH_LAST_VALS:
          /*
           * Possibly retrieve data...
           */
          gimp_get_data ("file_png_save", &pngvals);
          break;

        default:
          break;
        };

      if (status == GIMP_PDB_SUCCESS)
        {
          if (save_image (param[3].data.d_string,
                          image_ID, drawable_ID, orig_image_ID))
            {
              gimp_set_data ("file_png_save", &pngvals, sizeof (pngvals));
            }
          else
            {
              status = GIMP_PDB_EXECUTION_ERROR;
            }
        }

      if (export == GIMP_EXPORT_EXPORT)
        gimp_image_delete (image_ID);
    }
  else
    {
      status = GIMP_PDB_EXECUTION_ERROR;
    }

  values[0].data.d_status = status;
}


/*
 * 'load_image()' - Load a PNG image into a new image window.
 */

static gint32
load_image (gchar *filename)    /* I - File to load */
{
  int           i,              /* Looping var */
                trns,           /* Transparency present */
                bpp,            /* Bytes per pixel */
                image_type,     /* Type of image */
                layer_type,     /* Type of drawable/layer */
                empty,          /* Number of fully transparent indices */
                num_passes,     /* Number of interlace passes in file */
                pass,           /* Current pass in file */
                tile_height,    /* Height of tile in GIMP */
                begin,          /* Beginning tile row */
                end,            /* Ending tile row */
                num;            /* Number of rows to load */
  FILE          *fp;            /* File pointer */
  volatile gint32 image;        /* Image -- preserved against setjmp() */
  gint32        layer;          /* Layer */
  GimpDrawable  *drawable;      /* Drawable for layer */
  GimpPixelRgn  pixel_rgn;      /* Pixel region for layer */
  png_structp   pp;             /* PNG read pointer */
  png_infop     info;           /* PNG info pointers */
  guchar        **pixels,       /* Pixel rows */
                *pixel;         /* Pixel data */
  gchar         *progress;      /* Title for progress display... */
  guchar        alpha[256],     /* Index -> Alpha */
                *alpha_ptr;     /* Temporary pointer */

 /*
  * PNG 0.89 and newer have a sane, forwards compatible constructor.
  * Some SGI IRIX users will not have a new enough version though
  */

#if PNG_LIBPNG_VER > 88
  pp   = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  info = png_create_info_struct(pp);
#else
  pp = (png_structp)calloc(sizeof(png_struct), 1);
  png_read_init(pp);

  info = (png_infop)calloc(sizeof(png_info), 1);
#endif /* PNG_LIBPNG_VER > 88 */

  if (setjmp (pp->jmpbuf))
  {
    g_message (_("%s\nPNG error. File corrupted?"), filename);
    return image;
  }

  /* initialise image here, thus avoiding compiler warnings */

  image= -1;

 /*
  * Open the file and initialize the PNG read "engine"...
  */

  fp = fopen(filename, "rb");

  if (fp == NULL) 
    {
      g_message ("%s\nis not present or is unreadable", filename);
      gimp_quit ();
  }

  png_init_io(pp, fp);

  if (strrchr(filename, '/') != NULL)
    progress = g_strdup_printf (_("Loading %s:"), strrchr(filename, '/') + 1);
  else
    progress = g_strdup_printf (_("Loading %s:"), filename);

  gimp_progress_init(progress);
  g_free (progress);

 /*
  * Get the image dimensions and create the image...
  */

  png_read_info(pp, info);

 /*
  * Latest attempt, this should be my best yet :)
  */

  if (info->bit_depth == 16) {
    png_set_strip_16(pp);
  }

  if (info->color_type == PNG_COLOR_TYPE_GRAY && info->bit_depth < 8) {
    png_set_expand(pp);
  }

  if (info->color_type == PNG_COLOR_TYPE_PALETTE && info->bit_depth < 8) {
    png_set_packing(pp);
  }

 /*
  * Expand G+tRNS to GA, RGB+tRNS to RGBA
  */

  if (info->color_type != PNG_COLOR_TYPE_PALETTE &&
                       (info->valid & PNG_INFO_tRNS)) {
    png_set_expand(pp);
  }

 /*
  * Turn on interlace handling... libpng returns just 1 (ie single pass)
  * if the image is not interlaced
  */

  num_passes = png_set_interlace_handling(pp);

 /*
  * Special handling for INDEXED + tRNS (transparency palette)
  */

#if PNG_LIBPNG_VER > 99
  if (png_get_valid(pp, info, PNG_INFO_tRNS) &&
      info->color_type == PNG_COLOR_TYPE_PALETTE)
  {
    png_get_tRNS(pp, info, &alpha_ptr, &num, NULL);
    /* Copy the existing alpha values from the tRNS chunk */
    for (i= 0; i < num; ++i)
      alpha[i]= alpha_ptr[i];
    /* And set any others to fully opaque (255)  */
    for (i= num; i < 256; ++i)
      alpha[i]= 255;
    trns= 1;
  } else {
    trns= 0;
  }
#else
    trns= 0;
#endif /* PNG_LIBPNG_VER > 99 */

 /*
  * Update the info structures after the transformations take effect
  */

  png_read_update_info(pp, info);
  
  switch (info->color_type)
  {
    case PNG_COLOR_TYPE_RGB :           /* RGB */
        bpp        = 3;
        image_type = GIMP_RGB;
        layer_type = GIMP_RGB_IMAGE;
        break;

    case PNG_COLOR_TYPE_RGB_ALPHA :     /* RGBA */
        bpp        = 4;
        image_type = GIMP_RGB;
        layer_type = GIMP_RGBA_IMAGE;
        break;

    case PNG_COLOR_TYPE_GRAY :          /* Grayscale */
        bpp        = 1;
        image_type = GIMP_GRAY;
        layer_type = GIMP_GRAY_IMAGE;
        break;

    case PNG_COLOR_TYPE_GRAY_ALPHA :    /* Grayscale + alpha */
        bpp        = 2;
        image_type = GIMP_GRAY;
        layer_type = GIMP_GRAYA_IMAGE;
        break;

    case PNG_COLOR_TYPE_PALETTE :       /* Indexed */
        bpp        = 1;
        image_type = GIMP_INDEXED;
        layer_type = GIMP_INDEXED_IMAGE;
        break;
    default:                            /* Aie! Unknown type */
        g_message (_("%s\nPNG unknown color model"), filename);
        return -1;
  };

  image = gimp_image_new(info->width, info->height, image_type);
  if (image == -1)
  {
    g_message("Can't allocate new image\n%s", filename);
    gimp_quit();
  };

 /*
  * Create the "background" layer to hold the image...
  */

  layer = gimp_layer_new(image, _("Background"), info->width, info->height,
                         layer_type, 100, GIMP_NORMAL_MODE);
  gimp_image_add_layer(image, layer, 0);

  /*
   * Find out everything we can about the image resolution
   * This is only practical with the new 1.0 APIs, I'm afraid
   * due to a bug in libpng-1.0.6, see png-implement for details
   */

#if PNG_LIBPNG_VER > 99
  if (png_get_valid(pp, info, PNG_INFO_gAMA)) {
    /* I sure would like to handle this, but there's no mechanism to
       do so in Gimp :( */
  }
  if (png_get_valid(pp, info, PNG_INFO_oFFs)) {
    gimp_layer_set_offsets (layer, png_get_x_offset_pixels(pp, info),
                                   png_get_y_offset_pixels(pp, info));
  }
  if (png_get_valid(pp, info, PNG_INFO_pHYs)) {
    gimp_image_set_resolution(image,
         ((double) png_get_x_pixels_per_meter(pp, info)) * 0.0254,
         ((double) png_get_y_pixels_per_meter(pp, info)) * 0.0254);
  }
#endif /* PNG_LIBPNG_VER > 99 */

  gimp_image_set_filename(image, filename);

 /*
  * Load the colormap as necessary...
  */

  empty= 0; /* by default assume no full transparent palette entries */

  if (info->color_type & PNG_COLOR_MASK_PALETTE) {

#if PNG_LIBPNG_VER > 99
    if (png_get_valid(pp, info, PNG_INFO_tRNS)) {
      for (empty= 0; empty < 256 && alpha[empty] == 0; ++empty);
        /* Calculates number of fully transparent "empty" entries */

      gimp_image_set_cmap(image, (guchar *) (info->palette + empty),
                          info->num_palette - empty);
    } else {
      gimp_image_set_cmap(image, (guchar *)info->palette, info->num_palette);
    }
#else
    gimp_image_set_cmap(image, (guchar *)info->palette, info->num_palette);
#endif /* PNG_LIBPNG_VER > 99 */

  }

 /*
  * Get the drawable and set the pixel region for our load...
  */

  drawable = gimp_drawable_get(layer);

  gimp_pixel_rgn_init(&pixel_rgn, drawable, 0, 0, drawable->width,
                      drawable->height, TRUE, FALSE);

 /*
  * Temporary buffer...
  */

  tile_height = gimp_tile_height ();
  pixel       = g_new(guchar, tile_height * info->width * bpp);
  pixels      = g_new(guchar *, tile_height);

  for (i = 0; i < tile_height; i ++)
    pixels[i] = pixel + info->width * info->channels * i;

  for (pass = 0; pass < num_passes; pass ++)
  {
   /*
    * This works if you are only reading one row at a time...
    */

    for (begin = 0, end = tile_height;
         begin < info->height;
         begin += tile_height, end += tile_height)
    {
      if (end > info->height)
        end = info->height;

      num = end - begin;
        
      if (pass != 0) /* to handle interlaced PiNGs */
        gimp_pixel_rgn_get_rect(&pixel_rgn, pixel, 0, begin,
                                drawable->width, num);

      png_read_rows(pp, pixels, NULL, num);

      gimp_pixel_rgn_set_rect(&pixel_rgn, pixel, 0, begin,
                              drawable->width, num);

      gimp_progress_update(((double)pass + (double)end / (double)info->height) /
                           (double)num_passes);
    };
  };

 /*
  * Done with the file...
  */

  png_read_end(pp, info);
#if PNG_LIBPNG_VER < 10200      /* ?? Anyway, this function isn't in 1.2.0*/
  png_read_destroy(pp, info, NULL);
#endif

  g_free(pixel);
  g_free(pixels);
  free(pp);
  free(info);

  fclose(fp);

  if (trns) {
    gimp_layer_add_alpha(layer);
    drawable = gimp_drawable_get(layer);
    gimp_pixel_rgn_init(&pixel_rgn, drawable, 0, 0, drawable->width,
                        drawable->height, TRUE, FALSE);

    pixel  = g_new(guchar, tile_height * drawable->width * 2); /* bpp == 1 */

    for (begin = 0, end = tile_height;
         begin < drawable->height;
         begin += tile_height, end += tile_height)
    {
      if (end > drawable->height) end = drawable->height;
      num= end - begin;

      gimp_pixel_rgn_get_rect(&pixel_rgn, pixel, 0, begin,
                                drawable->width, num);

      for (i= 0; i < tile_height * drawable->width; ++i) {
        pixel[i*2+1]= alpha [ pixel[i*2] ];
        pixel[i*2]-= empty;
      }

      gimp_pixel_rgn_set_rect(&pixel_rgn, pixel, 0, begin,
                              drawable->width, num);
    }
    g_free(pixel);
  }

 /*
  * Update the display...
  */

  gimp_drawable_flush(drawable);
  gimp_drawable_detach(drawable);

  return (image);
}


/*
 * 'save_image ()' - Save the specified image to a PNG file.
 */

static gint
save_image (gchar  *filename,           /* I - File to save to */
            gint32  image_ID,           /* I - Image to save */
            gint32  drawable_ID,        /* I - Current drawable */
            gint32  orig_image_ID)      /* I - Original image before export */
{
  int           i, k,           /* Looping vars */
                bpp = 0,        /* Bytes per pixel */
                type,           /* Type of drawable/layer */
                num_passes,     /* Number of interlace passes in file */
                pass,           /* Current pass in file */
                tile_height,    /* Height of tile in GIMP */
                begin,          /* Beginning tile row */
                end,            /* Ending tile row */
                num;            /* Number of rows to load */
  FILE          *fp;            /* File pointer */
  GimpDrawable  *drawable;      /* Drawable for layer */
  GimpPixelRgn  pixel_rgn;      /* Pixel region for layer */
  png_structp   pp;             /* PNG read pointer */
  png_infop     info;           /* PNG info pointer */
  gint          num_colors;     /* Number of colors in colormap */
  gint          offx, offy;     /* Drawable offsets from origin */
  guchar        **pixels,       /* Pixel rows */
                *fixed,         /* Fixed-up pixel data */
                *pixel;         /* Pixel data */
  gchar         *progress;      /* Title for progress display... */
  gdouble       xres, yres;     /* GIMP resolution (dpi) */
  gdouble       gamma;          /* GIMP gamma e.g. 2.20 */
  png_color_16  background;     /* Background color */
  png_time      mod_time;       /* Modification time (ie NOW) */
  guchar        red, green,
                blue;           /* Used for palette background */
  time_t        cutime;         /* Time since epoch */
  struct tm     *gmt;           /* GMT broken down */

  guchar remap [256];    /* Re-mapping for the palette */

 /*
  * PNG 0.89 and newer have a sane, forwards compatible constructor.
  * Some SGI IRIX users will not have a new enough version though
  */

#if PNG_LIBPNG_VER > 88
  pp   = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  info = png_create_info_struct(pp);
#else
  pp = (png_structp)calloc(sizeof(png_struct), 1);
  png_write_init(pp);

  info = (png_infop)calloc(sizeof(png_info), 1);
#endif /* PNG_LIBPNG_VER > 88 */

  if (setjmp (pp->jmpbuf))
  {
    g_message (_("%s\nPNG error. Couldn't save image"), filename);
    return 0;
  }

 /*
  * Open the file and initialize the PNG write "engine"...
  */

  fp = fopen(filename, "wb");
  if (fp == NULL) {
    g_message (_("%s\nCouldn't create file"), filename);
    return 0;
  }

  png_init_io(pp, fp);

  if (strrchr(filename, '/') != NULL)
    progress = g_strdup_printf (_("Saving %s:"), strrchr(filename, '/') + 1);
  else
    progress = g_strdup_printf (_("Saving %s:"), filename);

  gimp_progress_init(progress);
  g_free (progress);

 /*
  * Get the drawable for the current image...
  */

  drawable = gimp_drawable_get (drawable_ID);
  type     = gimp_drawable_type (drawable_ID);

 /*
  * Set the image dimensions, bit depth, interlacing and compression
  */

  png_set_compression_level (pp, pngvals.compression_level);

  info->width          = drawable->width;
  info->height         = drawable->height;
  info->bit_depth      = 8;
  info->interlace_type = pngvals.interlaced;

 /* 
  * Initialise remap[]
  */
  for (i = 0; i < 256; i ++)
    {
      remap[i] = i;
    }

 /*
  * Set color type and remember bytes per pixel count 
  */

  switch (type)
  {
    case GIMP_RGB_IMAGE :
        info->color_type = PNG_COLOR_TYPE_RGB;
        bpp              = 3;
        break;
    case GIMP_RGBA_IMAGE :
        info->color_type = PNG_COLOR_TYPE_RGB_ALPHA;
        bpp              = 4;
        break;
    case GIMP_GRAY_IMAGE :
        info->color_type = PNG_COLOR_TYPE_GRAY;
        bpp              = 1;
        break;
    case GIMP_GRAYA_IMAGE :
        info->color_type = PNG_COLOR_TYPE_GRAY_ALPHA;
        bpp              = 2;
        break;
    case GIMP_INDEXED_IMAGE :
        bpp              = 1;
        info->color_type = PNG_COLOR_TYPE_PALETTE;
        info->valid      |= PNG_INFO_PLTE;
        info->palette= (png_colorp) gimp_image_get_cmap(image_ID, &num_colors);
        info->num_palette= num_colors;
        break;
    case GIMP_INDEXEDA_IMAGE :
        bpp              = 2;
        info->color_type = PNG_COLOR_TYPE_PALETTE;
        respin_cmap (pp, info, remap, image_ID, drawable); /* fix up transparency */
        break;
    default:
        g_message ("%s\nImage type can't be saved as PNG", filename);
        return 0;
  };

 /*
  * Fix bit depths for (possibly) smaller colormap images
  */
  
  if (info->valid & PNG_INFO_PLTE) {
    if (info->num_palette <= 2)
      info->bit_depth= 1;
    else if (info->num_palette <= 4)
      info->bit_depth= 2;
    else if (info->num_palette <= 16)
      info->bit_depth= 4;
    /* otherwise the default is fine */
  }

  /* All this stuff is optional extras, if the user is aiming for smallest
     possible file size she can turn them all off */

#if PNG_LIBPNG_VER > 99
  if (pngvals.bkgd) {
    gimp_palette_get_background(&red, &green, &blue);
      
    background.index = 0;
    background.red = red;
    background.green = green;
    background.blue = blue;
    background.gray = (red + green + blue) / 3;
    png_set_bKGD(pp, info, &background);
  }

  if (pngvals.gama) {
    gamma = gimp_gamma();
    png_set_gAMA(pp, info, 1.0 / (gamma != 1.00 ? gamma : DEFAULT_GAMMA));
  }

  if (pngvals.offs) {
    gimp_drawable_offsets(drawable_ID, &offx, &offy);
    if (offx != 0 || offy != 0) {
      png_set_oFFs(pp, info, offx, offy, PNG_OFFSET_PIXEL);
    }
  }

  if (pngvals.phys) {
    gimp_image_get_resolution (orig_image_ID, &xres, &yres);
    png_set_pHYs(pp, info, xres * 39.37, yres * 39.37, PNG_RESOLUTION_METER);
  }

  if (pngvals.time) {
    cutime= time(NULL); /* time right NOW */
    gmt = gmtime(&cutime);

    mod_time.year = gmt->tm_year + 1900;
    mod_time.month = gmt->tm_mon + 1;
    mod_time.day = gmt->tm_mday;
    mod_time.hour = gmt->tm_hour;
    mod_time.minute = gmt->tm_min;
    mod_time.second = gmt->tm_sec;
    png_set_tIME(pp, info, &mod_time);
  }

#endif /* PNG_LIBPNG_VER > 99 */

  png_write_info (pp, info);

 /*
  * Turn on interlace handling...
  */

  if (pngvals.interlaced)
    num_passes = png_set_interlace_handling(pp);
  else
    num_passes = 1;

 /*
  * Convert unpacked pixels to packed if necessary
  */

  if (info->color_type == PNG_COLOR_TYPE_PALETTE && info->bit_depth < 8)
    png_set_packing(pp);

 /*
  * Allocate memory for "tile_height" rows and save the image...
  */

  tile_height = gimp_tile_height();
  pixel       = g_new(guchar, tile_height * drawable->width * bpp);
  pixels      = g_new(guchar *, tile_height);

  for (i = 0; i < tile_height; i ++)
    pixels[i]= pixel + drawable->width * bpp * i;

  gimp_pixel_rgn_init(&pixel_rgn, drawable, 0, 0, drawable->width,
                      drawable->height, FALSE, FALSE);

  for (pass = 0; pass < num_passes; pass ++)
  {
      /* This works if you are only writing one row at a time... */
    for (begin = 0, end = tile_height;
         begin < drawable->height;
         begin += tile_height, end += tile_height)
      {
        if (end > drawable->height)
          end = drawable->height;

        num = end - begin;
        
        gimp_pixel_rgn_get_rect (&pixel_rgn, pixel, 0, begin, drawable->width, num);
        if (info->valid & PNG_INFO_tRNS) 
          {
            for (i = 0; i < num; ++i) 
              {
                fixed = pixels[i];
                for (k = 0; k < drawable->width; ++k) 
                  {
                    fixed[k] = (fixed[k*2+1] > 127) ? 
                               remap[fixed[k*2]] : 
                               0;
                     
                  }
              }
            /* Forgot this case before, what if there are too many colors? */
          } 
        else if (info->valid & PNG_INFO_PLTE && bpp == 2) 
          {
            for (i = 0; i < num; ++i) 
              {
                fixed = pixels[i];
                for (k = 0; k < drawable->width; ++k) 
                  {
                    fixed[k] = fixed[k*2];
                  }
              }
          }
        
        png_write_rows (pp, pixels, num);
        
        gimp_progress_update (((double)pass + (double)end /
                    (double)info->height) / (double)num_passes);
      };
  };

  png_write_end (pp, info);
#if PNG_LIBPNG_VER < 10200      /* ?? Anyway, this function isn't in 1.2.0*/
  png_write_destroy (pp);
#endif

  g_free (pixel);
  g_free (pixels);

 /*
  * Done with the file...
  */

  free (pp);
  free (info);

  fclose (fp);

  return (1);
}

static void
save_ok_callback (GtkWidget *widget,
                  gpointer  data)
{
  runme = TRUE;

  gtk_widget_destroy (GTK_WIDGET (data));
}

static void respin_cmap (png_structp pp, 
                         png_infop info, 
                         guchar *remap,
                         gint32 image_ID,
                         GimpDrawable *drawable) 
{
  static const guchar trans[] = { 0 };
  gint colors;
  guchar *before;
  gint transparent;
  gint cols, rows;
  GimpPixelRgn pixel_rgn;
  guchar *pixels;

  before= gimp_image_get_cmap(image_ID, &colors);
  cols = drawable->width;
  rows = drawable->height;

  gimp_pixel_rgn_init (&pixel_rgn, drawable, 0, 0,
                       drawable->width, drawable->height, 
                       FALSE, FALSE);

  pixels = (guchar *) g_malloc (drawable->width *
                                drawable->height * 2);
  
  gimp_pixel_rgn_get_rect (&pixel_rgn, pixels, 0, 0,
                           drawable->width, drawable->height);


  /* Try to find an entry which isn't actually used in the
     image, for a transparency index. */
  
  transparent = find_unused_ia_colour(pixels,
                                      drawable->width * drawable->height,
                                      &colors);
  
#if PNG_LIBPNG_VER > 99
  if (transparent != -1)  /* we have a winner for a transparent 
                           * index - do like gif2png and swap 
                           * index 0 and index transparent */
    {
      png_color palette[256];
      gint i;
      
      png_set_tRNS(pp, info, (png_bytep) trans, 1, NULL);

      /* Transform all pixels with a value = transparent to 
       * 0 and vice versa to compensate for re-ordering in palette 
       * due to png_set_tRNS() */

      remap[0] = transparent;
      remap[transparent] = 0;
      
      /* Copy from index 0 to index transparent - 1 to index 1 to 
       * transparent of after, then from transparent+1 to colors-1 
       * unchanged, and finally from index transparent to index 0. */

      for(i = 0; i < colors; i++)
        {
          palette[i].red = before[3 * remap[i]];
          palette[i].green = before[3 * remap[i] + 1];
          palette[i].blue = before[3 * remap[i] + 2];
        }

      /* Set index on all transparent pixels to 0 */
      
      png_set_PLTE(pp, info, palette, colors);
    } 
  else 
    {
      /* Inform the user that we couldn't losslessly save the 
       * transparency & just use the full palette */
      g_message ( _("Couldn't losslessly save transparency, saving opacity instead.\n"));
      png_set_PLTE (pp, info, (png_colorp) before, colors);
    }
#else
  info->valid     |= PNG_INFO_PLTE;
  info->palette=     (png_colorp) before;
  info->num_palette= colors;
#endif /* PNG_LIBPNG_VER > 99 */
 
  g_free (pixels);

}

static gint
save_dialog (void)
{
  GtkWidget *dlg;
  GtkWidget *frame;
  GtkWidget *table;
  GtkWidget *toggle;
  GtkWidget *scale;
  GtkObject *scale_data;

  dlg = gimp_dialog_new (_("Save as PNG"), "png",
                         gimp_standard_help_func, "filters/png.html",
                         GTK_WIN_POS_MOUSE,
                         FALSE, TRUE, FALSE,

                         _("OK"), save_ok_callback,
                         NULL, NULL, NULL, TRUE, FALSE,
                         _("Cancel"), gtk_widget_destroy,
                         NULL, 1, NULL, FALSE, TRUE,

                         NULL);

  gtk_signal_connect (GTK_OBJECT (dlg), "destroy",
                      GTK_SIGNAL_FUNC (gtk_main_quit),
                      NULL);

  frame = gtk_frame_new (_("Parameter Settings"));
  gtk_frame_set_shadow_type (GTK_FRAME (frame), GTK_SHADOW_ETCHED_IN);
  gtk_container_set_border_width (GTK_CONTAINER (frame), 6);
  gtk_box_pack_start (GTK_BOX (GTK_DIALOG (dlg)->vbox), frame, TRUE, TRUE, 0);
  gtk_widget_show (frame);

  table = gtk_table_new (2, 7, FALSE);
  gtk_table_set_col_spacings (GTK_TABLE (table), 4);
  gtk_table_set_row_spacings (GTK_TABLE (table), 2);
  gtk_container_set_border_width (GTK_CONTAINER (table), 4);
  gtk_container_add (GTK_CONTAINER (frame), table);
  gtk_widget_show (table);

  toggle = gtk_check_button_new_with_label (_("Interlacing (Adam7)"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 0, 1,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.interlaced);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.interlaced);
  gtk_widget_show (toggle);

  toggle = gtk_check_button_new_with_label (_("Save background color"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 1, 2,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.bkgd);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.bkgd);
  gtk_widget_show (toggle);

  toggle = gtk_check_button_new_with_label (_("Save gamma"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 2, 3,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.gama);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.gama);
  gtk_widget_show (toggle);

  toggle = gtk_check_button_new_with_label (_("Save layer offset"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 3, 4,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.offs);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.offs);
  gtk_widget_show (toggle);

  toggle = gtk_check_button_new_with_label (_("Save resolution"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 4, 5,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.phys);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.phys);
  gtk_widget_show (toggle);

  toggle = gtk_check_button_new_with_label (_("Save creation time"));
  gtk_table_attach (GTK_TABLE (table), toggle, 0, 2, 5, 6,
                    GTK_FILL, 0, 0, 0);
  gtk_signal_connect (GTK_OBJECT (toggle), "toggled",
                      GTK_SIGNAL_FUNC (gimp_toggle_button_update),
                      &pngvals.time);
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (toggle), pngvals.time);
  gtk_widget_show (toggle);

  scale_data = gtk_adjustment_new (pngvals.compression_level,
                                   0.0, 9.0, 1.0, 1.0, 0.0);
  scale      = gtk_hscale_new (GTK_ADJUSTMENT (scale_data));
  gtk_widget_set_usize (scale, SCALE_WIDTH, 0);
  gtk_scale_set_value_pos (GTK_SCALE (scale), GTK_POS_TOP);
  gtk_scale_set_digits (GTK_SCALE (scale), 0);
  gtk_range_set_update_policy (GTK_RANGE (scale), GTK_UPDATE_DELAYED);
  gimp_table_attach_aligned (GTK_TABLE (table), 0, 6,
                             _("Compression Level:"), 1.0, 1.0,
                             scale, 1, FALSE);
  gtk_signal_connect (GTK_OBJECT (scale_data), "value_changed",
                      GTK_SIGNAL_FUNC (gimp_int_adjustment_update),
                      &pngvals.compression_level);
  gtk_widget_show (scale);

  gtk_widget_show (dlg);

  gtk_main ();
  gdk_flush ();

  return runme;
}
