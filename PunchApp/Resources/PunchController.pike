
import Public.ObjectiveC;

inherit Cocoa.NSObject;
 
object app;
object defaults;
int icc;

static void create()
{
  werror("****\n**** create\n****\n");	
   app = Cocoa.NSApplication.sharedApplication();
  ::create();
}

// among other things here, we set default preferences.
void initialize()
{
  registerDefaultPreferences();
  setupPreferences();
}

void registerDefaultPreferences()
{
  defaults = Cocoa.NSUserDefaults.standardUserDefaults();
  mapping defs = ([]);
	
  defaults->registerDefaults_(defs);
}

void setupPreferences()
{
/*
  int bool;
  bool = (defaults->boolForKey_("cycleSensorIsPermanent"));
  CycleSensorTypeCheckbox->setState_(bool);
  CycleSensorMode = bool;

  werror("SET DEFAULT: %O\n", defaults->boolForKey_("cycleSensorIsPermanent"));
*/
}

void set_job_info()
{
	JobName->setStringValue_(jobinfo->name);
	Face->setStringValue_(jobinfo->face);
	Wedge->setStringValue_(jobinfo->wedge + "/" + jobinfo->set);
	Mould->setStringValue_(jobinfo->mould);
	LineLength->setStringValue_(jobinfo->linelength);
	Thermometer->setMinValue_(0.0);
	Thermometer->setDoubleValue_(0.0);
}

// callback from the load job button
void loadJob_(object a)
{
  object openPanel = Cocoa.NSOpenPanel.openPanel();

  openPanel->setAllowsMultipleSelection_(0);
  openPanel->setAllowedFileTypes_(({"rib"}));
  if(!openPanel->runModal()) return 0;

  mixed files = openPanel->URLs();
  if(!files->count())
    return 0;

  object file = files->lastObject();
  file = file->path();
  werror("fILE:%O\n",(string)( file->__objc_classname));
  werror("fILE:%O\n",(string)( file->UTF8String() ));
  jobinfo = Driver->loadRibbon((string)file->UTF8String() );
  set_job_info();

  CasterToggleButton->setEnabled_(1);
  SkipBeginButton->setEnabled_(1);

  app->mainMenu()->update();
}

/*
void toggleCycleSensorType_(object checkbox)
{
  int state = checkbox->state();

  werror("state: %O\n", state);
  werror("SET DEFAULT: %O\n", indices(defaults));

  defaults->setBool_forKey_(state, "cycleSensorIsPermanent");
  CycleSensorMode = state;
  werror("SET DEFAULT: %O\n", defaults->boolForKey_("cycleSensorIsPermanent"));	
}
*/

// callback from the start/stop button
void toggleCaster_(mixed ... args)
{
  int state = CasterToggleButton->state();
werror("!!\n!!\n!!state: %O\n!!\n!!\n", state);
  LoadJobButton->setEnabled_(!state);
  LoadJobItem->setEnabled_(!state);
  if(state) Driver->start();
  else Driver->stop();
}

void stopCaster()
{
  int state = CasterToggleButton->state();
  if(state)
  {
    CasterToggleButton->setState_(!state);
    LoadJobButton->setEnabled_(state);
    LoadJobItem->setEnabled_(state);
    SkipBeginButton->setEnabled_(1);
    Driver->stop();
  }	
}

// callback from the skip to beginning button
void backBegin_(object a)
{
  Driver->rewindRibbon();
}

void showPreferences_(object i)
{
  stopCaster();
  PreferenceWindow->setDelegate_(this);
  PreferenceWindow->makeKeyAndOrderFront_(i);
}

void windowWillClose_(object n)
{
}

void _finishedMakingConnections()
{
  initialize();
  MainWindow->makeKeyAndOrderFront_(this);
  werror("**** _AWAKING\n");
}

//
// Driver interface functions
//

int alert(string title, string body)
{
  call_out(_alert, 0, title, body);
}

int _alert(string title, string body)
{
  object a;
   a  = Cocoa.NSAlert();
   a->init();
   a->setInformativeText_(body);
   a->setMessageText_(title);
   a->addButtonWithTitle_("OK");
  Cocoa.NSApplication.sharedApplication()->activateIgnoringOtherApps_(1);
  return a->runModal();   
//  AppKit()->NSRunAlertPanel(title, body, "OK", "", "");
}	

void setCycleIndicator(int(0..1) status)
{
  CycleIndicator->setIntValue_(status);
}

  void setLineContents(string s)
  {
    LineContentsLabel->setStringValue_(s);
  }

  void setCurrentLine(int n)
  {
    string js = "highlight_line(" + n + ");";
    object win = LinesWebView->windowScriptObject();
    win->evaluateWebScript_(js);
  }

  void setLineStatus(string s)
  {
    CurrentLine->setStringValue_(s);
  }

  void setStatus(string s)
  {
    Status->setStringValue_(s);
  }

  void updateThermometer(float percent)
  {
    Thermometer->setDoubleValue_(percent);
  }

  void toggleCaster(int (0..1) state)
  { 
    CasterToggleButton->setState_(state);
    toggleCaster_(state);
  }

