
import Public.ObjectiveC;
object NSApp;

int main(int argc, array argv)
{
  NSApp = Cocoa.NSApplication.sharedApplication();
  add_constant("NSApp", NSApp);
  master()->add_module_path("modules");
//  NSApp->setDelegate_(this);
  NSApp->activateIgnoringOtherApps_(1);
  add_backend_to_runloop(Pike.DefaultBackend, 0.01);
werror("path: %O\n", master()->pike_module_path);
  return AppKit()->NSApplicationMain(argc, argv);
  
//return 0;
}

