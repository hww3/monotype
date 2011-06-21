import Public.ObjectiveC;

//inherit Cocoa.NSObject;

Cocoa.NSApplication app;
object Spinner;
Cocoa.NSButton LaunchBrowser;
Cocoa.NSTextField StartupLabel;
Cocoa.NSButton ViewLog;

void create()
{
//  ::create();
}

//spinner->startAnimation_(this);

void doViewLog_(Cocoa.NSObject obj)
{
	object s = Cocoa.NSWorkspace.sharedWorkspace();
	s->openFile_withApplication_(combine_path(getenv("HOME"), "Library/Application Support/Monotype Caster Control/debug.log"), "Console");	
}

void doLaunchBrowser_(Cocoa.NSObject obj)
{
  werror("whee!\n");

  object ws = Cocoa.NSWorkspace.sharedWorkspace();

  object url = Cocoa.NSURL.URLWithString_("http://localhost:5675");

  ws.openURL_(url);
}

void awakeFromNib(mixed q)
{
werror("***\n***\n*** awakeFromNib!\n***\n***\n");
}


object finserve;

int applicationShouldTerminateAfterLastWindowClosed_(object q)
{
  return 1;
}

void applicationWillFinishLaunching_(object event)
{
werror("***\n*** starting!\n**\n");
// are we running in a desktop mode?
	object fm = Cocoa.NSFileManager.defaultManager();
	string url = "~/Library/Application Support/Monotype Caster Control";
	object folder = Cocoa.NSString.stringWithCString_(url)->stringByExpandingTildeInPath();
werror("**** checking path...\n");
werror("**** " + (string)folder  + "\n");
	if(!fm->fileExistsAtPath_(folder))
	{
		fm->createDirectoryAtPath_attributes_(folder, ([]));
	}

   finserve = Fins.AdminTools.FinServe(({}));
   finserve->project = "Keyboard";
   finserve->config_name = "desktop";
   finserve->my_port = 5675;
   finserve->ready_callback = finserveStarted;
   Thread.Thread(finserve->do_startup);
  if(!finserve->started())
  {
    Spinner->startAnimation_(this);
    StartupLabel->setStringValue_("Starting...");
  }
}

void applicationWillTerminate_(object event)
{
werror("**** QUITTING\n");
  destruct(finserve);
}

void finserveStarted(object app)
{
Spinner->stopAnimation_(this);
LaunchBrowser->setEnabled_(1);
    StartupLabel->setStringValue_("Running");
}
