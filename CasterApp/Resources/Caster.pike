#!/usr/local/bin/pike

import Public.ObjectiveC;


object NSApp;

int main(int argc, array argv)
{  
  string sparklePath = combine_path(getcwd(), "../Frameworks/Sparkle.framework");
  int res = Public.ObjectiveC.load_bundle(sparklePath);
  werror("Loaded Sparkle: %O\n", (res==0)?"Okay":"Not Okay");

//  werror("wd: %s\n", getcwd());
  NSApp = Cocoa.NSApplication.sharedApplication();
  add_constant("NSApp", NSApp);
//  Cocoa.NSBundle.loadNibNamed_owner_("Caster", NSApp);
  NSApp->activateIgnoringOtherApps_(1);
//  werror("%O\n\n", master()->pike_module_path);

  NSApp->setDelegate_(this);
Pike.DefaultBackend.enable_external_runloop(1);
//  add_backend_to_runloop(Pike.DefaultBackend, 0.3);
  werror("NSApplicationMain returns: %d\n", AppKit()->NSApplicationMain(argc, argv));

 return 0;
}

void applicationDidFinishLaunching_(mixed q)
{

}
