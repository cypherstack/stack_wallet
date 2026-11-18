#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView *view)
{
    gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// X11 window icon from the icon theme or Flutter assets. Wayland ignores
// window icon requests and instead uses the .desktop file matching
// APPLICATION_ID. Only use a themed icon when the theme can supply a size GDK
// accepts; a lone 512 px icon exceeds X11's property-size limit.
static void set_window_icon(GtkWindow* window, FlDartProject* project) {
#ifdef GDK_WINDOWING_X11
  GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
  if (!GDK_IS_X11_DISPLAY(display)) {
    return;
  }

  GtkIconTheme* theme =
      gtk_icon_theme_get_for_screen(gtk_window_get_screen(window));
  bool has_usable_themed_icon = false;
  gint* themed_sizes = gtk_icon_theme_get_icon_sizes(theme, APPLICATION_ID);
  if (themed_sizes != nullptr) {
    for (gint* size = themed_sizes; *size != 0; ++size) {
      if (*size == -1 || (*size > 0 && *size <= 256)) {
        has_usable_themed_icon = true;
        break;
      }
    }
  }
  g_free(themed_sizes);
  if (has_usable_themed_icon) {
    gtk_window_set_icon_name(window, APPLICATION_ID);
    return;
  }

  g_autofree gchar* path =
      g_build_filename(fl_dart_project_get_assets_path(project), "assets",
                       "icon", "icon.png", nullptr);
  g_autoptr(GError) error = nullptr;
  g_autoptr(GdkPixbuf) icon =
      gdk_pixbuf_new_from_file_at_scale(path, 256, 256, TRUE, &error);
  if (icon == nullptr) {
    g_warning("No window icon: %s",
              error != nullptr ? error->message : "unknown image error");
    return;
  }
  if (gdk_pixbuf_get_width(icon) != gdk_pixbuf_get_height(icon)) {
    g_warning("Window icon must be square: %s", path);
    return;
  }
  gtk_window_set_icon(window, icon);
#else
  (void)window;
  (void)project;
#endif
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a traditional title bar by default for best compatibility across
  // desktop environments (KDE, XFCE, tiling WMs, etc.).
  // Set GTK_CSD=1 to use a GNOME-style header bar instead.
  const char* gtk_csd_env_var = getenv("GTK_CSD");
  if (gtk_csd_env_var && strcmp(gtk_csd_env_var, "1") == 0) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "PlaceHolderName");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "PlaceHolderName");
  }

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  set_window_icon(window, project);
  gtk_window_set_default_size(window, 1220, 500);
  gtk_widget_show(GTK_WIDGET(window));

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000 for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
