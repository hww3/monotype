
import Public.ObjectiveC;

inherit Cocoa.NSObject;
 
object app;
object defaults;
int icc;
int line;
object ribbon;
object ufwp;
object ufwpf;
mixed reconnect_id; // call_out id for reconnect.

mapping jobinfo;
int connected;
object punchInterface;
int sending;

string ufwtext=#"Ready to update Punch Interface firmware.

1. Ensure that the interface is connected to this computer's USB port.
2. Reset the interface by depressing the 'Reset' button.
";
function updateFwCallback_;

// Outlets and actions
object CancelUpdateButton;
object ConnectButton;
object ConnectMenuItem;
object HeaderCheckBox;
object InterfaceStatusText;
object JobInfoText;
object LoadButton;
object OpenMenuItem;
object ProgressIndicator;
object StartButton;
object StatusText;
object UpdateFirmwareMenuItem;
object UpdateFirmwareWindow;
object MainWindow;
object UpdateText;

void connectClicked_(object obj);
void headerCheckBoxClicked_(object obj);
void loadClicked_(object obj);
void startClicked_(object obj);
void updateFirmwareCancel_(object obj);
void updateFirmwareClicked_(object obj);

void connectClicked_(object obj)
{ 
  if(connected)
  {
    disconnect();
  }
  else
  {
    attemptConnect();
  }
}

void disconnect()
{ 
  remove_call_out(reconnect_id);
  LoadButton->setEnabled_(0);    
  HeaderCheckBox->setEnabled_(0);
  OpenMenuItem->setEnabled_(1);
  ribbon = 0;
  destruct(punchInterface);
  punchInterface = 0;
  setInterfaceStatus("Not Connected.");
  setStatus("");
  JobInfoText->setStringValue_("No Job Loaded.");
  StartButton->setEnabled_(0);
	ConnectButton->setTitle_("Connect");
  connected = !connected;
}

void connectSuccess(string interface)
{
  setInterfaceStatus("Interface v" + punchInterface->interface_version + " on " + interface + ".");
	ConnectButton->setTitle_("Disconnect");
  LoadButton->setEnabled_(1);
  HeaderCheckBox->setEnabled_(1);
  OpenMenuItem->setEnabled_(1);
  StartButton->setEnabled_(0);
  connected = !connected;
}

void connectFailure(string msg)
{
  alert("Connect Failed.", "Unable to connect to perforator interface.\n\n" + msg);
}

void fault(string f)
{
  alert("Punch Fault", "The punch interface has reported a fault: " + f);
}

void attemptConnect()
{
  remove_call_out(reconnect_id);
  punchInterface = PunchInterface.Interface();
  punchInterface->ui = this;
  punchInterface->version_callback = setVersionStatus;
  punchInterface->status_callback = setIntStatus;
  punchInterface->connect(connectSuccess, connectFailure);
}

void punchEnded()
{
  StartButton->setTitle_("Start");
  StartButton->setEnabled_(0);
  LoadButton->setEnabled_(1);
  OpenMenuItem->setEnabled_(1);
  HeaderCheckBox->setEnabled_(1);
  ProgressIndicator->setDoubleValue_(100.0);
  setStatus("Ribbon Complete.");
}

void headerCheckBoxClicked_(object obj){}
  
void loadClicked_(object obj)
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

  jobinfo = loadRibbon((string)file->UTF8String() );
  set_job_info();
  punchInterface->new_ribbon(ribbon, !HeaderCheckBox->state());
  HeaderCheckBox->setEnabled_(0);
  ProgressIndicator->setDoubleValue_(0.0);
  StartButton->setEnabled_(1);
  line = 0;
  sending = 0;
  }

void startClicked_(object obj)
{
  sending = !sending;
  
  if(sending)
  {
    if(ribbon && punchInterface)
    {
      StartButton->setTitle_("Stop"); 
      LoadButton->setEnabled_(0);
      HeaderCheckBox->setEnabled_(0);
      OpenMenuItem->setEnabled_(0);
      punchInterface->start();
    }
  }
  else
  {
    if(ribbon && punchInterface)
    {

      StartButton->setTitle_("Start"); 

      LoadButton->setEnabled_(1);
      HeaderCheckBox->setEnabled_(1);
      OpenMenuItem->setEnabled_(1);
      punchInterface->stop();
    }    
  }
}
  
void updateFirmwareCancel_(object obj)
{
  if(ufwp)
  {
    updateFwCallback_ = lambda(mixed x){};
    ufwp->kill(9);
    ufwp = 0;
  }
  UpdateFirmwareWindow->close();
}
  
object openPanel;

void updateFirmwareClicked_(object obj)
{
  if(!openPanel)
  {
    openPanel = Cocoa.NSOpenPanel.openPanel();
    openPanel->setAllowedFileTypes_(({"pfw"}));
    openPanel->setAllowsMultipleSelection_(0);
  }
  
  if(!openPanel->runModal()) return 0;

  mixed files = openPanel->URLs();
  if(!files->count())
    return 0;

  object file = files->lastObject();
  file = file->path();

  if(!file_stat((string)file))
  {
    alert("Invalid firmware file", "Firmware file is not valid.");
    return;
  } 
  
  disconnect();

  ufwpf = Stdio.File();
  object p = ufwpf->pipe();
  updateFwCallback_ = updateFwCallback__;
  
  ufwp = Process.create_process(({combine_path(getcwd(), "hid_bootloader_cli"), "-mmcu=at90usb1286", "-w", (string)file}), (["stdout": p, "stderr": p, "callback": updateFwCallback]));
 // UpdateFirmwareWindow->setDelegate_(this);
  call_out(openUpdateWindow, 0.1);
}

void openUpdateWindow()
{
  if(ufwp && !ufwp->status())
  {
    UpdateText->setStringValue_(ufwtext);
    UpdateFirmwareWindow->makeKeyAndOrderFront_(this);    
  }
}

void updateFwCallback(object process)
{
  updateFwCallback_(process);
}

void updateFwCallback__(object process)
{
  int rc;
  int status = process->status();
  if(status == 0) // running
  {
    call_out(openUpdateWindow, 0.1);
    return;
  }
  else if(status == 2)
  {
    rc = process->wait();
    if(rc != 0)
    {
      updateFirmwareCancel_(this);
      alert("Update Failed", "Firmware update failed:\n\n" + ufwpf->read(2000, 0));
    }
    else
    {
      alert("Success!", "Firmware update was successful.");
      ufwp = 0;
      updateFirmwareCancel_(this);
      reconnect_id = call_out(updateFirmwareReconnect, 10.0);
    }
  }
}

void updateFirmwareReconnect()
{
  attemptConnect();
}

static void create()  
{
  werror("****\n**** create\n****\n");	
   app = Cocoa.NSApplication.sharedApplication();  
  ::create();
}

mapping loadRibbon(string filename)
{
   ribbon = ((program)"Ribbon")(filename);
   ribbon->line_changed_func = ribbon_line_changed;
   jobinfo = ribbon->get_info();
   setStatus(sprintf("Loaded %d codes in %d lines.", jobinfo->code_count, jobinfo->line_count));
   return jobinfo;
}

void ribbon_line_changed(object ribbon)
{
  array current_line = ribbon->get_current_line_contents();
  line++;
  setStatus("Sent line " + (line));
  float pct = (line-1) / (float)(jobinfo->line_count);
  ProgressIndicator->setDoubleValue_(pct*100);
  //setLineContents(reverse(current_line) *"");
}

void set_job_info()
{
	JobInfoText->setStringValue_(jobinfo->name);
	ProgressIndicator->setMinValue_(0.0);
	ProgressIndicator->setDoubleValue_(0.0);
}

void setStatus(string s)
{
  StatusText->setStringValue_(s);
} 

void setVersionStatus(string s)
{
  setInterfaceStatus("Firmware Version " + s + " on " + punchInterface->interface_device);  
}

void setIntStatus(string s)
{
  if(!s) return;
  
  if(search(s, "FAULT") != -1)
  {
    StartButton->setEnabled_(0);
  }
  else if(search(s, "OFFLINE") != -1)
  {
    StartButton->setEnabled_(0);    
  }
  else if(search(s, "ONLINE") != -1)
  {
    StartButton->setEnabled_(1);  
  }
  setInterfaceStatus(s);
}

void setInterfaceStatus(string s)
{
  InterfaceStatusText->setStringValue_(s);
}

void initialize()
{
//  app->mainMenu()->update();  
}

#if 0
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


void showPreferences_(object i)
{
  stopCaster();
  PreferenceWindow->setDelegate_(this);
  PreferenceWindow->makeKeyAndOrderFront_(i);
}

void windowWillClose_(object n)
{
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

  void updateThermometer(float percent)
  {
    Thermometer->setDoubleValue_(percent);
  }

  void toggleCaster(int (0..1) state)
  { 
    CasterToggleButton->setState_(state);
    toggleCaster_(state);
  }

#endif /* 0 */

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

