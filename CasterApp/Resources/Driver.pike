import Public.ObjectiveC;

  constant all_codes = ({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
                         "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14",
                         "S", "0005", "0075"});

  object plugin;
  object ribbon;
  object ui;
  mapping jobinfo;

  int wasStarted;

  int inManualControl = 0;
  array(string) manualCode = ({});

  void enableManualControl()
  {
werror("**\n** manual control enabled.\n**\n");
    allOff();
    wasStarted = plugin->started;	  
    inManualControl = 1;
    plugin->start();
  }

  void disableManualControl()
  {
	werror("disableManualControl()\n");
    allOff();
    if(!wasStarted)
      plugin->stop();
    inManualControl = 0;
  }

  void allOn()
  {
    manualCode = copy_value(all_codes);
  }
  
  void allOff()
  {
    manualCode = ({});
  }

  void enablePin(object control, string pin)
  {

    manualCode = __builtin.uniq_array(manualCode + ({pin}));
werror("enablePin(%O): manualCode is %s\n", pin, manualCode*"");

  }

  void disablePin(object control, string pin)
  {
werror("disablePin(%O)\n", pin);
    manualCode -= ({pin});
  }
 
  array getNextCode()
  {
    if(inManualControl) 
    {
      werror("getNextCode(): manual code %s\n", manualCode*"");
      return manualCode;
    }
    else if(ribbon)
      return ribbon->get_next_code(); 
	else
	  throw(Error.Generic("No ribbon and not in manual control!\n"));
  }

  void stop()
  {
	
	werror("Driver.stop()\n");
    if(inManualControl)
      return;

    plugin->stop();		
  }

  void start()
  {
	werror("Driver.start()\n");
    if(inManualControl)
      return;

    plugin->start();
  }

  void forwardLine()
  {
    if(inManualControl)
      return;

    ribbon->skip_to_line_end();
  }

  void backwardLine()
  {
    if(inManualControl)
      return;

    ribbon->skip_to_line_beginning();
    processedCode();
  }

  void codesEnded()
  {
	
  }
  
  void rewindRibbon()
  {
    if(inManualControl)
      return;
 
    ribbon->rewind(-1);
    processedCode();
  }
  
  int currentPos()
  {
    return ribbon->current_pos;	
  }

  // called by anyone except the UI when the processing should be stopped, such as end of ribbon.
  void doStop()
  {
	//return;
	ui->CasterToggleButton->setState_(0);
	ui->toggleCaster_(0);
  }

  void setStatus(string s)
  {
	werror("%O\n", ui->Status);
	ui->Status->setStringValue_(s);
  }

  void processedCode()
  {
    if(!inManualControl)
	ui->Thermometer->setDoubleValue_(((float)ribbon->current_pos/jobinfo->code_count)*100);
  }

  mapping loadRibbon(string filename)
  {
     ribbon = ((program)"Ribbon")(filename);

     jobinfo = ribbon->get_info();
     setStatus(sprintf("Loaded %d codes in %d lines.", jobinfo->code_count, jobinfo->line_count));
     return jobinfo;
  }

  static void create(object _ui, mapping config)
  {
	mixed e = catch{
  	  plugin = ((program)"Plugins.pmod/MonotypeInterface")(this, config);
    };

    if(e)
    {
/*	
	  object a = Cocoa.NSAlert()->init();
	  a->addButtonWithTitle_("OK");
	  a->setMessageText_("No Monotype interface found, using Simulator.");
	  a->runModal();
*/
  AppKit()->NSRunAlertPanel("Interface not present", "No Monotype interface found, using simulator.", "OK", "", "");
	
	  plugin = ((program)"Plugins.pmod/Simulator")(this, config);
    }
	ui = _ui;
  }
