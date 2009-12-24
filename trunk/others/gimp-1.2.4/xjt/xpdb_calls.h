/*  xpdb_calls.h
 *
 */
/* The GIMP -- an image manipulation program
 * Copyright (C) 1995 Spencer Kimball and Peter Mattis
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

/* revision history:
 * version 1.1.18a; 2000/03/07  hof: tattoo_state
 * version 1.1.16a; 2000/02/04  hof: path lockedstaus, tattoo set procedures
 * version 1.1.15b; 2000/01/28  hof: parasites part2
 * version 1.1.15;  2000/01/20  hof: parasites
 * version 1.02.00; 1999/02/01  hof: PDB-calls to load/save resolution tattoos and parasites
 *                                   (needs GIMP 1.1.1)-- UNDER CONSTRUCTION ---
 * version 1.01.00; 1998/11/22  hof: PDB-calls to load/save guides under GIMP 1.1
 * version 1.00.00; 1998/10/26  hof: 1.st (pre) release
 */

#ifndef _XPDB_CALLS_H
#define _XPDB_CALLS_H

#include "libgimp/gimp.h"

gint p_procedure_available(gchar *proc_name);
gint p_get_gimp_selection_bounds (gint32 image_id, gint32 *x1, gint32 *y1, gint32 *x2, gint32 *y2);
gint p_gimp_selection_load (gint32 image_id, gint32 channel_id);
int  p_layer_set_linked (gint32 layer_id, gint32 new_state);
gint p_layer_get_linked(gint32 layer_id);

gint32 p_gimp_image_floating_sel_attached_to(gint32 image_id);
gint   p_gimp_floating_sel_attach(gint32 layer_id, gint32 drawable_id);
gint   p_gimp_floating_sel_rigor(gint32 layer_id, gint32 undo);
gint   p_gimp_floating_sel_relax(gint32 layer_id, gint32 undo);

gint32 p_gimp_image_add_guide(gint32 image_id, gint32 position, gint32 orientation);
gint32 p_gimp_image_findnext_guide(gint32 image_id, gint32 guide_id);
gint32 p_gimp_image_get_guide_position(gint32 image_id, gint32 guide_id);
gint32 p_gimp_image_get_guide_orientation(gint32 image_id, gint32 guide_id);

gint   p_gimp_image_get_resolution(gint32 image_id, float *xresolution, float *yresolution);
gint   p_gimp_image_set_resolution(gint32 image_id, float xresolution, float yresolution);
gint32 p_gimp_layer_get_tattoo(gint32 layer_id);
gint32 p_gimp_channel_get_tattoo(gint32 channel_id);

gchar** p_gimp_drawable_parasite_list (gint32 drawable_id, gint32 *num_parasites);
gchar** p_gimp_image_parasite_list (gint32 image_id, gint32 *num_parasites);

gint    p_gimp_path_set_points(gint32 image_id, gchar *name,
                       gint32 path_type, gint32 num_points, gdouble *path_points);
gdouble* p_gimp_path_get_points(gint32 image_id, gchar *name,
                       gint32 *path_type, gint32 *path_closed, gint32 *num_points);

gchar**  p_gimp_path_list(gint32 image_id, gint32 *num_paths);
gchar*   p_gimp_path_get_current(gint32 image_id);
gint     p_gimp_path_set_current(gint32 image_id, gchar *name);
gint32   p_gimp_path_get_locked(gint32 image_id, gchar *name);
gint     p_gimp_path_set_locked(gint32 image_id, gchar *name, gint32 lockstatus);
gint32   p_gimp_path_get_tattoo(gint32 image_id, gchar *name);
gint     p_gimp_path_set_tattoo(gint32 image_id, gchar *name, gint32 tattoovalue);
gint     p_gimp_layer_set_tattoo(gint32 layer_id, gint32 tattoovalue);
gint     p_gimp_channel_set_tattoo(gint32 channel_id, gint32 tattoovalue);
gint     p_gimp_image_set_tattoo_state(gint32 image_id, gint32 tattoo_state);
gint32   p_gimp_image_get_tattoo_state(gint32 image_id);

#endif
