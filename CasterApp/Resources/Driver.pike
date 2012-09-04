import Public.ObjectiveC;

  constant all_codes = ({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
                         "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14",
                         "S", "0005", "0075"});

  int CycleSensorDebounce; // set in the preference window.
  object plugin;
  object ribbon;
  object ui;
  mapping jobinfo = ([]);

  int wasStarted;

  int inManualControl = 0;
  int forced = 0;

  array(string) manualCode = ({});

void jump_to_line(int line)
  {
	werror("\n\n\njump_to_line: %O\n", line);
   	ribbon->rewind(-1);
	setLineStatus(ribbon->current_line);
    processedCode();
	if(line <= 0) return;
	
	do
	{
		werror("\n\nskipping forward.\n");
	    ribbon->skip_to_line_end();
		ribbon->get_next_code();
		setLineStatus(ribbon->current_line);
		if(!ribbon->current_code) break;
		werror("cl: %O\n", ribbon->current_line);
		processedCode();
	} while (ribbon->current_line < line);
	ribbon->return_code();
ribbon->current_line--;
  }
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

  void forceOn()
  {
	forced = 1;
	plugin->do_start_code(getNextCode());
  }

  void forceOff()
  {
	forced = 0;
	plugin->do_start_code(({}));
  }

  void allOn()
  {
    manualCode = copy_value(all_codes);
    if(forced)
       plugin->do_start_code(getNextCode());
  }
  
  void allOff()
  {
    manualCode = ({});
    if(forced)
       plugin->do_start_code(getNextCode());
  }

  void enablePin(object control, string pin)
  {

    manualCode = __builtin.uniq_array(manualCode + ({pin}));
    if(forced)
       plugin->do_start_code(getNextCode());
werror("enablePin(%O): manualCode is %s\n", pin, manualCode*"");

  }

  void disablePin(object control, string pin)
  {
werror("disablePin(%O)\n", pin);
    manualCode -= ({pin});
    if(forced)
       plugin->do_start_code(getNextCode());
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
	setLineStatus(ribbon?ribbon->current_line:"0");
  }

  void backwardLine()
  {
    if(inManualControl)
      return;

    ribbon->skip_to_line_beginning();
	setLineStatus(ribbon->current_line);
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
	setLineStatus(ribbon->current_line);
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
	setLineStatus(ribbon?ribbon->current_line:"0");
  }

  void processedCode()
  {
    if(!inManualControl)
	ui->Thermometer->setDoubleValue_(((float)ribbon->current_pos/jobinfo->code_count)*100);
  }

  mapping loadRibbon(string filename)
  {
     ribbon = ((program)"Ribbon")(filename);
     ribbon->line_changed_func = ribbon_line_changed;
     jobinfo = ribbon->get_info();
     setStatus(sprintf("Loaded %d codes in %d lines.", jobinfo->code_count, jobinfo->line_count));
     setLineStatus("0");
     return jobinfo;
  }

  void setLineStatus(string s)
  {
//	werror("%O\n", ui->Status);
	ui->CurrentLine->setStringValue_(s + "/" + jobinfo->line_count);
  }

  void setLineContents(string s)
  {
//	werror("%O\n", ui->Status);
	ui->LineContentsLabel->setStringValue_(reverse(s));
  }

  void setCycleStatus(int(0..1) status)
  {
    ui->CycleIndicator->setIntValue_(status);
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

  void ribbon_line_changed(object ribbon)
  {
	array current_line = ribbon->get_current_line_contents();
	setLineContents(current_line *"");
  }
