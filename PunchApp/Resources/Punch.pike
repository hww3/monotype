#!/usr/local/bin/pike

import Public.ObjectiveC;


object NSApp;

int main(int argc, array argv)
{  
  string sparklePath = combine_path(getcwd(), "../Frameworks/Sparkle.framework");
  int res = Public.ObjectiveC.load_bundle(sparklePath);
  werror("Loaded Sparkle: %O\n", (res==0)?"Okay":"Not Okay");

  NSApp = Cocoa.NSApplication.sharedApplication();
  add_constant("NSApp", NSApp);
  NSApp->activateIgnoringOtherApps_(1);

  NSApp->setDelegate_(this);

  Pike.DefaultBackend.enable_external_runloop(1);
  werror("NSApplicationMain returns: %d\n", AppKit()->NSApplicationMain(argc, argv));

 return 0;
}

void applicationDidFinishLaunching_(mixed q)
{

}
