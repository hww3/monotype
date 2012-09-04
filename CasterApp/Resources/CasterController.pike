
import Public.ObjectiveC;

inherit Cocoa.NSObject;

object Driver;

object SkipForwardButton;
object SkipBackwardButton;
object SkipBeginButton;
object CasterToggleButton;
object LoadJobButton;
object PinControlItem;
object PinControlWindow;
object JumpToLineWindow;
object JumpToLineItem;

object JumpToLineBox;
object MainWindow;
object PreferenceWindow;

/* Preference controls */
object CycleSensorTypeCheckbox;
object DebounceSlider;

object CurrentLine;
object LineContentsLabel;

object JobName;
object Face;
object Wedge;
object Mould;
object LineLength;

object Thermometer;
object Status;

object CycleIndicator;

object IgnoreCycleButton;

object cA;
object cB;
object cC;
object cD;
object cE;
object cF;
object cG;
object cH;
object cI;
object cJ;
object cK;
object cL;
object cM;
object cN;

object cS;
object c0005;
object c0075;

object c1;
object c2;
object c3;
object c4;
object c5;
object c6;
object c7;
object c8;
object c9;
object c10;
object c11;
object c12;
object c13;
object c14;

mapping jobinfo;

int CycleSensorMode;
int CycleSensorDebounce;

object defaults;
object app;
int icc;
array buttonstotouch = 
	({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", 
		"S", "0005", "0075"});

static void create()
{
   Driver = ((program)"Driver")(this);

  ::create();
	
   app = Cocoa.NSApplication.sharedApplication();

}

// among other things here, we set default preferences.
void initialize()
{
	registerDefaultPreferences();
	setupPreferences();
//	throw(Error.Generic("whee!"));
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
	object defaults = Cocoa.NSUserDefaults.standardUserDefaults();
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

  if(!openPanel->runModalForTypes_(({"rib"}))) return;

  mixed files = openPanel->filenames();
  if(sizeof(files))
    foreach(files;;mixed file)
    {
	werror("fILE:%O\n",(string)( file->__objc_classname));
      jobinfo = Driver->loadRibbon((string)file->UTF8String());
      set_job_info();
    }
  CasterToggleButton->setEnabled_(1);
  JumpToLineItem->setEnabled_(1);
  app->mainMenu()->update();
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
object pcmi;
object jlmi;
int was_caster_enabled;

void showPinControl_(object i)
{
	werror("showPinControl_(%s)\n", (string)(i->title()->UTF8String()));
	PinControlWindow->setDelegate_(this);
//	if(!PinControlWindow->isVisible())
		PinControlWindow->makeKeyAndOrderFront_(i);
	pcmi = i;
	pcmi->setEnabled_(0);
	JumpToLineItem->setEnabled_(0);
	app->mainMenu()->update();
	was_caster_enabled = CasterToggleButton->isEnabled();
	CasterToggleButton->setEnabled_(0);
	Driver->enableManualControl();
	ignoreCycleClicked_(IgnoreCycleButton);
	allOff_(i);
}

void showPreferences_(object i)
{
	stopCaster();
	PreferenceWindow->setDelegate_(this);
	PreferenceWindow->makeKeyAndOrderFront_(i);

//	werror("\n\n\ncode: %O\n\n\n", code);
/*
	JumpToLineWindow->makeKeyAndOrderFront_(i);
	
	jlmi = i;
	jlmi->setEnabled_(0);
	app->mainMenu()->update();	
	*/
}

void showJumpToLine_(object i)
{
	stopCaster();
	JumpToLineWindow->setDelegate_(this);
	int code = app->runModalForWindow_(JumpToLineWindow);
	JumpToLineWindow->close();
	
	if(code) // we clicked OK
	{
		string line_to_jump_to = (string)JumpToLineBox->stringValue();
		werror("destination line: %O\n", line_to_jump_to);
		Driver->jump_to_line((int)line_to_jump_to);
	}
//	werror("\n\n\ncode: %O\n\n\n", code);
/*
	JumpToLineWindow->makeKeyAndOrderFront_(i);
	
	jlmi = i;
	jlmi->setEnabled_(0);
	app->mainMenu()->update();	
	*/
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
	if(n->var_object == PinControlWindow)
	{
		werror("windowWillClose_()");
		pcmi->setEnabled_(1);
		JumpToLineItem->setEnabled_(1);
		app->mainMenu()->update();
		
		Driver->disableManualControl();
		CasterToggleButton->setEnabled_(was_caster_enabled);
	}
}

void jumpCancelClicked_(object b)
{
	app->stopModalWithCode_(0);
//  JumpToLineWindow->performClose_(b);
}

void jumpOKClicked_(object b)
{
	app->stopModalWithCode_(1);
  //JumpToLineWindow->performClose_(b);
}

void _finishedMakingConnections()
{
	
	initialize();
	MainWindow->makeKeyAndOrderFront_(this);
	werror("**** _AWAKING\n");
//	sleep(100);
	
}
