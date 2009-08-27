
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

mapping jobinfo;

object app;

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

void loadJob_(object a)
{
  object openPanel = Cocoa.NSOpenPanel.openPanel();

  if(!openPanel->runModalForTypes_(({"rib"}))) return;

  mixed files = openPanel->filenames();
  if(sizeof(files))
    foreach(files;;mixed file)
    {
      jobinfo = Driver->loadRibbon((string)file);
      set_job_info();
    }
  CasterToggleButton->setEnabled_(1);

}

void toggleCaster_(mixed ... args)
{
  int state = CasterToggleButton->state();

  LoadJobButton->setEnabled_(!state);
  SkipForwardButton->setEnabled_(state);
  SkipBackwardButton->setEnabled_(state);
  SkipBeginButton->setEnabled_(state);
  if(state) Driver->start();
  else Driver->stop();
}

void backBegin_(object a)
{
  Driver->rewindRibbon();
}

void backLine_(object a)
{
  Driver->backwardLine();
}

void forwardLine_(object a)
{
  Driver->forwardLine();
}

void allOn_(object b)
{
	werror("allOn_(%s)\n", (string)
	b->title());
}

void allOff_(object b)
{
	werror("allOff_(%s)\n", (string)b->title());
	
}

void checkClicked_(object b)
{
	string pin = (string)b->title();
	werror("checkClicked_(%s, %d)\n", pin, b->state());
	
	if(b->state())
	  Driver->enablePin(b);
	else
  	  Driver->disablePin(b);
	
}

void showPinControl_(object i)
{
	werror("showPinControl_(%s)\n", (string)(i->title()));
	PinControlWindow->setDelegate_(this);
	if(!PinControlWindow->isVisible())
		PinControlWindow->makeKeyAndOrderFront_(i);
	i->setEnabled_(0);
	app->mainMenu()->update();
	Driver->enableManualControl();
}

void windowWillClose_(object n)
{
	werror("windowWillClose_()");
	PinControlItem->setEnabled_(1);
	app->mainMenu()->update();
	
	Driver->disableManualControl();
}