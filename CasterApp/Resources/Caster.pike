#!/usr/local/bin/pike

import Public.ObjectiveC;


object NSApp;

int main(int argc, array argv)
{  
//  werror("wd: %s\n", getcwd());
  NSApp = Cocoa.NSApplication.sharedApplication();
  add_constant("NSApp", NSApp);
//  Cocoa.NSBundle.loadNibNamed_owner_("Caster", NSApp);
  NSApp->activateIgnoringOtherApps_(1);
//  werror("%O\n\n", master()->pike_module_path);

  NSApp->setDelegate_(this);

  add_backend_to_runloop(Pike.DefaultBackend, 0.3);
  werror("NSApplicationMain returns: %d\n", AppKit()->NSApplicationMain(argc, argv));

 return 0;
}

void applicationDidFinishLaunching_(mixed q)
{

}