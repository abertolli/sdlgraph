/*
 * Displays a triangle with Open/GL | Mesa
 *
 * (DISCLAIMER not quite 100% OK)
 *
 * Author: Ivo Clarysse <soggie@riv.be>
 *
 * In Public Domain
 */

#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <GL/glu.h>

int redraw_needed=TRUE;

Display *dpy=NULL;
GLXContext glx_context;

GLfloat cam_xspin=0.0;
GLfloat cam_yspin=0.0;
GLfloat cam_zspin=0.0;
GLfloat cam_xpos=0.0;
GLfloat cam_ypos=0.0;
GLfloat cam_zpos=-5.0;

GtkWidget *glarea;

void object_redraw();

/* Define model in displaylist */
void            object_define()
{
  glNewList(1, GL_COMPILE_AND_EXECUTE);
  glClear(GL_COLOR_BUFFER_BIT);

  glBegin(GL_LINE_LOOP);
  glVertex3f(-1, 0, 0);
  glVertex3f( 0, -1, 0);
  glVertex3f( 1, -1, 0);
  glEnd();
  
  glEndList();
}


void object_redraw()
{
static int list_inited=FALSE;

  if (!redraw_needed) return;

  glXMakeCurrent(dpy,GDK_WINDOW_XWINDOW(glarea->window),glx_context);
  glShadeModel(GL_FLAT);
  glClearColor(0.0,0.0,0.0,0.0);
  glColor3f(1.0, 1.0, 1.0);
  glLineWidth(1.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glTranslatef(cam_xpos, cam_ypos, cam_zpos);
  glRotatef(cam_xspin, 1.0, 0.0, 0.0);        /* rotate modelmatrix */
  glRotatef(cam_yspin, 0.0, 1.0, 0..0);        /* rotate modelmatrix */
  glRotatef(cam_zspin, 0.0, 0.0, 1.0);        /* rotate modelmatrix */

  if (list_inited) glCallList(1);
  else { 
    object_define(); 
    list_inited=TRUE; 
  }

  glFlush();
  printf("Before swap\n");
  glXSwapBuffers(dpy,GDK_WINDOW_XWINDOW(glarea->window));
  printf("After swap\n");

  redraw_needed=FALSE;

}


/*
 * Callback function for 'Quit' button
 *
 */
void quit_button(GtkWidget *widget, gpointer *data)
{
  gtk_main_quit();
}

/*
 * Callback for GTK events in glarea 
 *
 */
gint glarea_events(GtkWidget *area, GdkEvent *event)
{
GdkEventConfigure *configevent;

  switch (event->type) {
    case GDK_EXPOSE:
      redraw_needed=TRUE;
      object_redraw();
      break;

    case GDK_CONFIGURE:  /* aka Resize */
      printf("entry: GDK_CONFIGURE\n");
      redraw_needed=TRUE;
      configevent=(GdkEventConfigure *)event;
    
      /* Resize OpenGL context in glarea */
      glMatrixMode(GL_PROJECTION);   
      glLoadIdentity();             
      glFrustum(-1.0, 1.0, -1.0, 1.0, 1.5, 20.0);
      glViewport(0, 0, configevent->width, configevent->height); 
      glMatrixMode(GL_MODELVIEW);       
      printf("exit: GDK_CONFIGURE\n");
      break;

    default:
      break;
    }
  return (FALSE);
}


void gui_init()
{
  gint TimerTag;
  GtkWidget *appwindow, *vbox, *button;
  XVisualInfo *vi;
  int dbuf[] = {GLX_DOUBLEBUFFER,GLX_RED_SIZE,1,GLX_GREEN_SIZE,1,
                GLX_BLUE_SIZE,1,None};

  appwindow=gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(appwindow), "GL-GTK Test");

  vbox=gtk_vbox_new(FALSE,0);

  /* Upper row */

  glarea = gtk_drawing_area_new();
  gtk_drawing_area_size(GTK_DRAWING_AREA(glarea),300,300);
  gtk_widget_set_events(glarea,GDK_EXPOSURE_MASK);
  gtk_signal_connect(GTK_OBJECT(glarea), "event", (GtkSignalFunc)glarea_events, NULL);
  gtk_box_pack_start(GTK_BOX(vbox), glarea, FALSE, FALSE, 0);
  gtk_widget_show(glarea);


  /* Lower row */

  button=gtk_button_new_with_label("Quit");
  gtk_signal_connect(GTK_OBJECT(button), "clicked", GTK_SIGNAL_FUNC(quit_button), NULL);
  gtk_box_pack_start(GTK_BOX(vbox), button, FALSE, FALSE, 0);
  gtk_widget_show(button);


  /* ** */
  gtk_widget_show(vbox);
  gtk_container_add(GTK_CONTAINER(appwindow),vbox);

  gtk_widget_show(appwindow);

  printf("check\n");

  /* Initialize OpenGL */
  dpy=GDK_WINDOW_XDISPLAY(appwindow->window);
  vi=glXChooseVisual(dpy,DefaultScreen(dpy),dbuf);

  if (vi==NULL) { fprintf(stderr,"ERROR: Could not create visual\n"); exit(-1); }
  if (vi->class != TrueColor) printf("Non-TrueColor visual selected\n"); 
  printf("Selected visual = %d\n",vi->visualid);
  glx_context = glXCreateContext(dpy,vi,None,GL_TRUE);
  if (glx_context==NULL) { fprintf(stderr,"ERROR: Could not create context\n"); exit(-1); }

  /* Initialize OpenGL context for rendering */
  printf("glXMakeCurrent\n"); 
  glXMakeCurrent(dpy,GDK_WINDOW_XWINDOW(glarea->window),glx_context);
  glShadeModel(GL_FLAT);
  glClearColor(0.0,0.0,0.0,0.0);
  glColor3f(1.0, 1.0, 1.0);
  glLineWidth(1.0);

}


/**********************************
 *
 * Main function - delegate :)
 *
 **********************************/
int main(int argc, char *argv[])
{
  gtk_init (&argc, &argv);

printf("gui_init\n");
  gui_init();

printf("main widget loop\n");
  gtk_main();

  return 0;
}

