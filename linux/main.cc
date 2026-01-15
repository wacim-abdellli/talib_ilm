static void my_application_activate(GApplication* application) {
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gtk_window_set_title(window, "Talib Ilm");

  // 📱 Mobile-like default size
  gtk_window_set_default_size(window, 290, 84);

  // ❌ Do NOT start fullscreen
  gtk_window_unmaximize(window);

  // Optional: disable resizing
  // gtk_window_set_resizable(window, FALSE);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  FlView* view = fl_view_new(project);

  gtk_window_set_child(window, GTK_WIDGET(view));
  gtk_widget_show(GTK_WIDGET(window));
}
