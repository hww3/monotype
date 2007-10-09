
import Public.ObjectiveC;

inherit Cocoa.NSObject;

object Driver;

object SkipForwardButton;
object SkipBackwardButton;
object SkipBeginButton;
object CasterToggleButton;
object LoadJobButton;

object JobName;
object Face;
object Wedge;
object Mould;

object Thermometer;
object Status;

mapping jobinfo;

class nr
{
  inherit Cocoa.NSResponder;

  void create()
{
	::create();
}

  int acceptsFirstResponder()
  {
	return 1;
  }

}

static void create()
{
   Driver = ((program)"Driver")(this);
}

void set_job_info()
{
	JobName->setStringValue_(jobinfo->name);
	Face->setStringValue_(jobinfo->face);
	Wedge->setStringValue_(jobinfo->wedge + "/" + jobinfo->set);
	Mould->setStringValue_(jobinfo->mould);
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
//      werror("file: %O\n", (string)file);
      jobinfo = Driver->loadRibbon((string)file);
      set_job_info();
    }
  CasterToggleButton->setEnabled_(1);
//  NSApp->keyWindow()->setNextResponder_(nr()->init());

}

void toggleCaster_(mixed ... args)
{
//werror("ARGS: %O\n", args);
  int state = CasterToggleButton->state();
//  werror("toggleCaster_(%O)\n", LoadJobButton->isEnabled());
  LoadJobButton->setEnabled_(!state);
  SkipForwardButton->setEnabled_(state);
  SkipBackwardButton->setEnabled_(state);
  SkipBeginButton->setEnabled_(state);
  if(state) Driver->start();
  else Driver->stop();
}

void backBegin_(object a)
{
//  werror("backBegin_(%O)\n", a);
  Driver->rewindRibbon();
}

void backLine_(object a)
{
//  werror("backLine_(%O)\n", a);
  Driver->backwardLine();
}

void forwardLine_(object a)
{
//  werror("forwardLine_(%O)\n", a);
  Driver->forwardLine();
}


