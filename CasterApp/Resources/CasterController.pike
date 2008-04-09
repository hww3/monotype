//
//  this is the main Controller for the Monotype Caster Control UI.
//

import Public.ObjectiveC;

inherit Cocoa.NSObject;

// the driver object acts as an intermediary between the ribbon,
// this ui and the caster hardware interface
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
object LineLength;

object Thermometer;
object Status;

mapping jobinfo;

static void create()
{
   Driver = ((program)"Driver")(this);

  ::create();
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

// callback from the "Load Job" button
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

// callback from the "Start/Stop" button
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

// callback from the "full rewind" button
void backBegin_(object a)
{
  Driver->rewindRibbon();
}

// calback from the "back one line" button
void backLine_(object a)
{
  Driver->backwardLine();
}

// callback from the "forward one line" button
void forwardLine_(object a)
{
  Driver->forwardLine();
}
