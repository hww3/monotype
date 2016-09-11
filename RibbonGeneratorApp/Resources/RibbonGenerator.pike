import Public.ObjectiveC;
object NSApp;

int main(int argc, array argv)
{
    mixed err;
    master()->add_module_path("modules");
    System.syslog(5, "Starting Ribbon Generator, PID = " + getpid());
    master()->add_predefine("SINGLE_TENANT", "1");

    string sparklePath = combine_path(getcwd(), "../Frameworks/Sparkle.framework");
    int res = Public.ObjectiveC.load_bundle(sparklePath);
    werror("Loaded Sparkle: %O\n", (res==0)?"Okay":"Not Okay");
    res = Public.ObjectiveC.load_bundle("/System/Library/Frameworks/WebKit.framework");
    werror("Loaded WebKit: %O\n", (res==0)?"Okay":"Not Okay");
    NSApp = Cocoa.NSApplication.sharedApplication();
    add_constant("NSApp", NSApp);
    NSApp->activateIgnoringOtherApps_(1);
    Pike.DefaultBackend.enable_external_runloop(1);
    werror("path: %O\n", master()->pike_module_path);
    return AppKit()->NSApplicationMain(argc, argv);
}
