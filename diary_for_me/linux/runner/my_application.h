#ifndef FLUTTER_MY_APPLICATION_H_
#define FLUTTER_MY_APPLICATION_H_

#include <gtk/gtk.h>

<<<<<<< HEAD
G_DECLARE_FINAL_TYPE(MyApplication, my_application, MY, APPLICATION,
=======
<<<<<<< HEAD
G_DECLARE_FINAL_TYPE(MyApplication,
                     my_application,
                     MY,
                     APPLICATION,
=======
G_DECLARE_FINAL_TYPE(MyApplication, my_application, MY, APPLICATION,
>>>>>>> location
>>>>>>> oji/merge
                     GtkApplication)

/**
 * my_application_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #MyApplication.
 */
MyApplication* my_application_new();

#endif  // FLUTTER_MY_APPLICATION_H_
