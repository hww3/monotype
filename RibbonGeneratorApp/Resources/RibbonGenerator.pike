import Public.ObjectiveC;
object NSApp;

int parent;
int port;
object finserve; 

int main(int argc, array argv)
{
  foreach(argv;int c;string arg)
  {
    if(arg == "--run-generator")
    {
      port = (int)argv[c+1];
      if(!port) port = 5675;
    }

    if(arg == "--parent-process")
    {
      parent = (int)argv[c+1];
    }
  }

  master()->add_module_path("modules");

  if(port)
  {
    master()->add_predefine("SINGLE_TENANT", "1");
     finserve = master()->resolv("Fins.AdminTools.FinServe")(({}));  
werror("PROJECT: %O\n", finserve);
//     finserve->project = "Keyboard";
//     finserve->config_name = "desktop";
//     finserve->my_port = 5675;
     finserve->no_virtual = 1;
     finserve->ready_callback = finserveStarted;
     finserve->do_startup(({"Keyboard"}), ({"desktop"}), 5675);    
      return -1;
  }
  else
  {
    master()->add_predefine("SINGLE_TENANT", "1");
    string sparklePath = combine_path(getcwd(), "../Frameworks/Sparkle.framework");
    int res = Public.ObjectiveC.load_bundle(sparklePath);
    werror("Loaded Sparkle: %O\n", (res==0)?"Okay":"Not Okay");
    NSApp = Cocoa.NSApplication.sharedApplication();
    add_constant("NSApp", NSApp);
//  NSApp->setDelegate_(this);
    NSApp->activateIgnoringOtherApps_(1);
    add_backend_to_runloop(Pike.DefaultBackend, 0.01);
    werror("path: %O\n", master()->pike_module_path);
    return AppKit()->NSApplicationMain(argc, argv);
  }
  
//return 0;
}

void finserveStarted(object app)
{
  if(parent)
  {
    werror("SIGNALLING WE'RE UP.\n");
    kill(parent, signum("USR1"));
  }
}
