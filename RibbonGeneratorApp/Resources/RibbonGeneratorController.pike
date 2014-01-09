import Public.ObjectiveC;

//inherit Cocoa.NSObject;

string URL = "http://localhost:5675/";

Cocoa.NSApplication app;
object Spinner;
Cocoa.NSButton LaunchBrowser;
Cocoa.NSTextField StartupLabel;
Cocoa.NSButton ViewLog;
Cocoa.NSButton BackupData;

object server;

void create()
{
//  ::create();
}

//spinner->startAnimation_(this);

void doBackupData_(Cocoa.NSObject obj)
{
  object savePanel = Cocoa.NSSavePanel.savePanel();

  savePanel->setNameFieldStringValue_("RibbonGeneratorData " + Calendar.now()->format_ymd() + ".sqlite3");
  savePanel->setTitle_("Backup Ribbon Generator Data");
 
//  if(!savePanel->runModal()) return 0;
  return;

  mixed files = savePanel->URL();

  object file = files->path();
  werror("fILE:%O\n",(string)( file->__objc_classname));
  werror("fILE:%O\n",(string)( file->UTF8String() ));
  string res;
  res = Protocols.HTTP.post_url(URL + "_backup_db/", (["destination": utf8_to_string(file->UTF8String()), "PSESSIONID": "12345"]))->data();
//werror("RES: %O\n", res);
  if(res != "OK") 
  {
    throw(Error.Generic("An error occurred backing up your database: " + res + "\n"));
  }
//  werror("app: %O\n", values(finserve->apps)[0]->get_application()->do_generic_method(copy_db, utf8_to_string(file->UTF8String())));

//  Stdio.cp(finserve, utf8_to_string(file->UTF8String()));
}

void copy_db(string dest)
{
  string src = master()->resolv("Fins.DataSource._default")->path;
  werror("Copying database from %O to %O\n", src, dest);
  Stdio.cp(src, dest);
}

void doViewLog_(Cocoa.NSObject obj)
{
	object s = Cocoa.NSWorkspace.sharedWorkspace();
	s->openFile_withApplication_(combine_path(getenv("HOME"), "Library/Application Support/Monotype Caster Control/debug.log"), "Console");	
}

void doLaunchBrowser_(Cocoa.NSObject obj)
{
  werror("whee!\n");

  object ws = Cocoa.NSWorkspace.sharedWorkspace();

  object url = Cocoa.NSURL.URLWithString_(URL);

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


   string ap = __APPPATH;
   if(ap[0] != '/')
   {
werror("AP: %O\n", ap);
werror("CWD: %O\n", getcwd());
     ap = combine_path(getcwd(), "../../..",  ap);
   } 

   finserve = master()->resolv("Fins.AdminTools.SimpleFinServe")(({}));

   finserve->ready_callback = finserveStarted;
   finserve->failure_callback = finserveFailed;
   finserve->project = "Keyboard";
   finserve->my_port = 5675;
   finserve->config_name = "desktop";
   finserve->do_startup(({"Keyboard"}), ({"desktop"}), 5675);

//   Thread.Thread(finserve->do_startup, ({"Keyboard"}), ({"desktop"}), 5675);

  if(!finserve->started())
  {
    Spinner->startAnimation_(this);
    StartupLabel->setStringValue_("Starting...");
  }

}


void applicationWillTerminate_(object event)
{
werror("**** QUITTING\n");
//  destruct(finserve);
}

void finserveStarted(int x)
{
Spinner->stopAnimation_(this);
LaunchBrowser->setEnabled_(1);
BackupData->setEnabled_(1);
    StartupLabel->setStringValue_("Running");
werror("Threads: %O\n", Thread.all_threads());
}

void finserveFailed(int x)
{
Spinner->stopAnimation_(this);
LaunchBrowser->setEnabled_(0);
BackupData->setEnabled_(0);
    StartupLabel->setStringValue_("Startup Failed");
}
