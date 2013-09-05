
import Public.ObjectiveC;

inherit "CasterControllerOutlets";
inherit Cocoa.NSObject;
 
object app;
object defaults;
int icc;

object pcmi;
object jlmi;
int showingPinControl;
int jumpToLineCode = 0;
// 
// 0075 + 0005 = Trip Galley
// 0005 = Stop pump
// 0075 = Start pump
//

static void create()
{
  ::create();
//  Driver = ((program)"Driver")(this);
werror("****\n**** create\n****\n");	
   app = Cocoa.NSApplication.sharedApplication();
}

// among other things here, we set default preferences.
void initialize()
{
//werror("this: %O\n", mkmapping(indices(this), values(this)));
	registerDefaultPreferences();
	setupPreferences();
}

void registerDefaultPreferences()
{
	defaults = Cocoa.NSUserDefaults.standardUserDefaults();
	mapping defs = ([]);
	
	defs->cycleSensorIsPermanent = "YES";
	defs->cycleSensorDebounce = "25"; // cycle sensor debounce in ms, range 0 - 55 ms
	
	defaults->registerDefaults_(defs);
}

void setupPreferences()
{
	int bool;
	bool = (defaults->boolForKey_("cycleSensorIsPermanent"));
	CycleSensorTypeCheckbox->setState_(bool);
	CycleSensorMode = bool;

	bool = (defaults->integerForKey_("cycleSensorDebounce"));
	DebounceSlider->setIntegerValue_(bool);
        Driver->CycleSensorDebounce = bool;		

	werror("SET DEFAULT: %O\n", defaults->boolForKey_("cycleSensorIsPermanent"));
	werror("SET DEFAULT: %O\n", defaults->integerForKey_("cycleSensorDebounce"));
}

void set_job_info()
{
	JobName->setStringValue_(jobinfo->name);
	Face->setStringValue_(jobinfo->face);
	Wedge->setStringValue_(jobinfo->wedge + "/" + jobinfo->set);
	Mould->setStringValue_(jobinfo->mould);
	LineLength->setStringValue_(jobinfo->linelength + " pica");
	Thermometer->setMinValue_(0.0);
	Thermometer->setDoubleValue_(0.0);
}

// callback from the load job button
void loadJob_(object a)
{
  object openPanel = Cocoa.NSOpenPanel.openPanel();

  openPanel->setAllowsMultipleSelection_(0);

  if(!openPanel->runModalForTypes_(({"rib"}))) return 0;

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
  JumpToLineItem->setEnabled_(1);
  app->mainMenu()->update();
  updateLinesView();
}

void updateLinesView()
{
  werror("LinesWebView: %O\n", sort(indices(LinesWebView->mainFrame())));
  LinesWebView->mainFrame()->loadHTMLString_baseURL_(Driver->getRibbonContents(), Cocoa.NSURL.URLWithString_("file:///"));
}

void debounceChanged_(object slider)
{
  werror("debounceChanged_(%O)\n", slider);
  int x = slider->intValue();
  defaults->setInteger_forKey_(x, "cycleSensorDebounce");
  Driver->CycleSensorDebounce = x;
  werror("debounceChanged_(%O)\n", x);
}

void toggleCycleSensorType_(object checkbox)
{
  
	int state = checkbox->state();
	
	werror("state: %O\n", state);
	werror("SET DEFAULT: %O\n", indices(defaults));

	defaults->setBool_forKey_(state, "cycleSensorIsPermanent");
	CycleSensorMode = state;
	werror("SET DEFAULT: %O\n", defaults->boolForKey_("cycleSensorIsPermanent"));
	
}

// callback from the start/stop button
void toggleCaster_(mixed ... args)
{
  int state = CasterToggleButton->state();
werror("state: %O\n", state);
  LoadJobButton->setEnabled_(!state);
  LoadJobItem->setEnabled_(!state);
  SkipForwardButton->setEnabled_(state);
  SkipBackwardButton->setEnabled_(state);
  SkipBeginButton->setEnabled_(state);
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
	  SkipForwardButton->setEnabled_(!state);
	  SkipBackwardButton->setEnabled_(!state);
	  SkipBeginButton->setEnabled_(!state);
	  Driver->stop();
  }	
}

// callback from the skip to beginning button
void backBegin_(object a)
{
  Driver->rewindRibbon();
}

// callback from the backward one line button
void backLine_(object a)
{
  Driver->backwardLine();
}

// callback from the forward line button
void forwardLine_(object a)
{
  Driver->forwardLine();
}

void allOn_(object b)
{
	werror("allOn_(%s)\n", (string)
	b->title()->UTF8String());
	werror("allOff_(%s)\n", (string)b->title()->UTF8String());
	foreach(buttonstotouch;; string b)
	{
	  this["c" + b]->setState_(1);
	}
	Driver->allOn();
}

void allOff_(object b)
{
	werror("allOff_(%s)\n", (string)b->title()->UTF8String());
	foreach(buttonstotouch;; string but)
	{
	  this["c" + but]->setState_(0);
	}
	Driver->allOff();
}

void checkClicked_(object b)
{
	string pin = (string)b->title()->UTF8String();
	werror("checkClicked_(%s, %d)\n", pin, b->state());
	
	if(b->state())
	  Driver->enablePin(b, pin);
	else
  	  Driver->disablePin(b, pin);
}


void showPinControl_(object i)
{
	werror("showPinControl_(%s)\n", (string)(i->title()->UTF8String()));
	if(!showingPinControl)
	{
	  ManualPinControl->toggle_(i);
	  was_caster_enabled = CasterToggleButton->isEnabled();
	  CasterToggleButton->setEnabled_(0);
	  Driver->enableManualControl();
	  ignoreCycleClicked_(IgnoreCycleButton);
	  allOff_(i);
  	pcmi->setEnabled_(0);
  	JumpToLineItem->setEnabled_(0);
  	app->mainMenu()->update();
  }
	else
	{
	  ManualPinControl->toggle_(i);
	  werror("windowWillClose_()");
	  pcmi->setEnabled_(1);
	  JumpToLineItem->setEnabled_(1);
	  app->mainMenu()->update();
	  Driver->disableManualControl();
	  CasterToggleButton->setEnabled_(was_caster_enabled);
  }
  	showingPinControl = !showingPinControl;

}

void showPreferences_(object i)
{
  stopCaster();
  PreferenceWindow->setDelegate_(this);
  PreferenceWindow->makeKeyAndOrderFront_(i);
}

void showJumpToLine_(object i)
{
  stopCaster();
  JumpToLineWindow->setDelegate_(this);
  jumpToLineCode = app->runModalForWindow_(JumpToLineWindow);
  JumpToLineWindow->close();
  if(jumpToLineCode) // we clicked OK
  {
    mixed line_to_jump_to = JumpToLineBox->intValue();
    werror("destination line: %O\n", line_to_jump_to);
    Driver->jump_to_line((int)line_to_jump_to);
  }
	
	jumpToLineCode = 0; 
}

void ignoreCycleClicked_(object button)
{
	icc = button->state();
	if(icc)
	{
		Driver->forceOn();
	}
	else
	{
		Driver->forceOff();
	}
}



void windowWillClose_(object n)
{
}

void jumpCancelClicked_(object b)
{
	app->stopModalWithCode_(0);
}

void jumpOKClicked_(object b)
{
	app->stopModalWithCode_(1);
}

void enablePumpClicked_(object b)
{
  Driver->enablePump();
}

void disablePumpClicked_(object b)
{
  Driver->disablePump();
}

void tripGalleyClicked_(object b)
{
  Driver->tripGalley();
}

void _finishedMakingConnections()
{
	
	initialize();
	MainWindow->makeKeyAndOrderFront_(this);
	werror("**** _AWAKING\n");
//	sleep(100);
	
}

//
// Driver interface functions
//

void alert(string title, string	body)
{
  AppKit()->NSRunAlertPanel(title, body, "OK", "", "");
}	

void setCycleIndicator(int(0..1) status)
{
  CycleIndicator->setIntValue_(status);
}

  void setLineContents(string s)
  {
    LineContentsLabel->setStringValue_(s);
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

