
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
object Set;
object Mould;

object Line;
object Character;
object Status;

mapping jobinfo;

static void create()
{
   Driver = ((program)"Driver")(this);
}

void set_job_info()
{
	JobName->setStringValue_(jobinfo->name);
	Face->setStringValue_(jobinfo->face);
	Wedge->setStringValue_(jobinfo->wedge);
	Set->setStringValue_(jobinfo->set);
	Mould->setStringValue_(jobinfo->mould);
}

void loadJob_(object a)
{

  object openPanel = Cocoa.NSOpenPanel.openPanel();
  if(!openPanel->runModalForTypes_(({"rib"}))) return;

  mixed files = openPanel->filenames();
  if(sizeof(files))
    foreach(files;;mixed file)
    {
      werror("file: %O\n", (string)file);
      jobinfo = Driver->loadRibbon((string)file);
      set_job_info();
    }
  CasterToggleButton->setEnabled_(1);
}

void toggleCaster_(mixed ... args)
{
werror("ARGS: %O\n", args);
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
  werror("backBegin_(%O)\n", a);
}

void backLine_(object a)
{
  werror("backLine_(%O)\n", a);
}

void forwardLine_(object a)
{
  werror("forwardLine_(%O)\n", a);
}


