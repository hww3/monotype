
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

object JobName;
object Face;
object Wedge;
object Mould;
object LineLength;

object Thermometer;
object Status;

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

object app;

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
      jobinfo = Driver->loadRibbon((string)file);
      set_job_info();
    }
  CasterToggleButton->setEnabled_(1);

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
	b->title());
	werror("allOff_(%s)\n", (string)b->title());
	foreach(buttonstotouch;; string b)
	{
	  this["c" + b]->setState_(1);
	}
	Driver->allOn();
}

void allOff_(object b)
{
	werror("allOff_(%s)\n", (string)b->title());
	foreach(buttonstotouch;; string but)
	{
	  this["c" + but]->setState_(0);
	}
	Driver->allOff();
}

void checkClicked_(object b)
{
	string pin = (string)b->title();
	werror("checkClicked_(%s, %d)\n", pin, b->state());
	
	if(b->state())
	  Driver->enablePin(b, pin);
	else
  	  Driver->disablePin(b, pin);
	
}
object pcmi;
int was_caster_enabled;

void showPinControl_(object i)
{
	werror("showPinControl_(%s)\n", (string)(i->title()));
	PinControlWindow->setDelegate_(this);
//	if(!PinControlWindow->isVisible())
		PinControlWindow->makeKeyAndOrderFront_(i);
	pcmi = i;
	pcmi->setEnabled_(0);
	app->mainMenu()->update();
	was_caster_enabled = CasterToggleButton->isEnabled();
	CasterToggleButton->setEnabled_(0);
	allOff_(i);
	Driver->enableManualControl();
}


void windowWillClose_(object n)
{
	werror("windowWillClose_()");
	pcmi->setEnabled_(1);
	app->mainMenu()->update();
	
	Driver->disableManualControl();
	CasterToggleButton->setEnabled_(was_caster_enabled);
}
