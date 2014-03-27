
  constant all_codes = ({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
                         "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14",
                         "S", "0005", "0075"});

  int AutoStartStopMode; // set in the preference window.
  int CycleSensorDebounce; // set in the preference window.
  object plugin;
  object ribbon;
  object ui;
  mapping jobinfo = ([]);

  int wasStarted;

  int inManualControl = 0;
  int forced = 0;
  int started = 0;
  
  array(string) manualCode = ({});

  ADT.Queue next_code = ADT.Queue();
  
  string get_current_coarse()
  {
    return ribbon?ribbon->get_current_coarse():"15";    
  }
  
  string get_current_fine()
  {
    return ribbon?ribbon->get_current_fine():"15"; 
  }
  
  void set_next_code(array(string) nextCode)
  {
    next_code->put(nextCode);
  }

  void jump_to_line(int line)
  {
//	werror("\n\n\njump_to_line: %O\n", line);
       if(!ribbon) return;
   	ribbon->rewind(-1);
	setLineStatus(ribbon->current_line);
    processedCode();
	if(line <= 0) return;
	
	do
	{
//		werror("\n\nskipping forward.\n");
	    ribbon->skip_to_line_end();
		ribbon->get_next_code();
		setLineStatus(ribbon->current_line);
		if(!ribbon->current_code) break;
	//	werror("cl: %O\n", ribbon->current_line);
		processedCode();
	} while (ribbon->current_line < line);
	ribbon->return_code();
ribbon->current_line--;
  }
  
  void enableManualControl()
  {
//werror("**\n** manual control enabled.\n**\n");
    allOff();
    wasStarted = plugin->started;	  
    inManualControl = 1;
    plugin->start();
  }

  void disableManualControl()
  {
//	werror("disableManualControl()\n");
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
//werror("enablePin(%O): manualCode is %s\n", pin, manualCode*"");

  }

  void disablePin(object control, string pin)
  {
//werror("disablePin(%O)\n", pin);
    manualCode -= ({pin});
    if(forced)
       plugin->do_start_code(getNextCode());
  }
 
  array getNextCode()
  {
    // next_code always takes precedence, regardless of start/stop status.
    if(!next_code->is_empty())
    {
      return next_code->get();
    }
    else if(inManualControl) 
    {
      //      werror("getNextCode(): manual code %s\n", manualCode*"");
      return manualCode;
    }
    // if we're not in manual control and not started, return an empty code
    else if(!started)
    {
      return ({});
    }
    else if(ribbon)
    {
      // get the next code and make a note of the current wedge settings.
      return ribbon->get_next_code();
    }
	  else
	  {
	    throw(Error.Generic("No ribbon and not in manual control!\n"));
    }
  }

  void enablePump()
  {
    set_next_code(({"0005", get_current_fine()}));    
    set_next_code(({"0075", get_current_coarse()}));    
  }
  
  void disablePump()
  {
    set_next_code(({"0005", get_current_fine()}));
  }

  void tripGalley()
  {
    set_next_code(({"0005", "0075", get_current_fine()}));    
  }

  void stop()
  {
	
	werror("Driver.stop()\n");
    if(inManualControl)
      return;

    started = 0;
    if(AutoStartStopMode)
      disablePump();
    plugin->stop();		
  }

  void start()
  {
	werror("Driver.start()\n");
    if(inManualControl)
      return;

    started = 1;
    if(AutoStartStopMode)
      enablePump();
    plugin->start();
  }

  void forwardLine()
  {
    if(inManualControl)
      return;

    setStatus("Seeking next line.");
    ribbon->skip_to_line_end();
    setLineStatus(ribbon?ribbon->current_line:"0");
  }

  void backwardLine()
  {
    if(inManualControl)
      return;

    setStatus("Seeking previous line.");
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
    if(!ribbon) return;

    ribbon->rewind(-1);
	setLineStatus(ribbon->current_line);
    processedCode();
  }
  
  int currentPos()
  {
    return ribbon->current_pos;	
  }

  void ribbon_line_changed(object ribbon)
  {
	array current_line = ribbon->get_current_line_contents();
	setLineContents(reverse(current_line) *"");
  }

  static void create(object _ui, mapping config)
  {
    ui = _ui;
    mixed e = catch{
      plugin = ((program)"Plugins.pmod/MonotypeInterface")(this, config);
    };

    if(e)
    {
      ui->alert("Interface not present", "No Monotype interface found, using simulator.");
      werror(master()->describe_backtrace(e));
      plugin = ((program)"Plugins.pmod/Simulator")(this, config);
    }
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

  //
  //
  // UI Specific code below.
  //
  //

  // called by anyone except the UI when the processing should be stopped, such as end of ribbon.
  void doStop()
  {
    ui->toggleCaster(0);
  }

  string getRibbonContents()
  {
    String.Buffer buf = String.Buffer();
    buf+= "<html>";
    buf+=
#"<script type=\"text/javascript\">
  var linehighlighted;
function highlight_line(line)
{
  var i;
  var span;
  var url = location.href; 
  if(linehighlighted)
  {
    span = document.getElementById(\"line\" + linehighlighted);
    span.style['background-color'] = '';
  }

  location.href = \"#line\"+ (line-3);  
  span = document.getElementById(\"line\" + line);
  
if(span)
  {
    span.style['background-color'] = 'yellow';
    linehighlighted = line;
  }
  else linehighlighted = 0;
  history.replaceState(null,null,url); 
}
</script>
";
    buf+= "<table>";

    if(ribbon)
    {
      foreach(ribbon->line_contents; int x; array line)
      {
        buf += "<tr id=\"line" + (x+1) + "\"><td><a name=\"line" + x+3 + "\"><a onClick='caster.jumpToLine_(" + (x+1) + ");'><b>" + (x+1) + "</a> &nbsp;</b> </td>\n";
        buf += "<td><tt>" + (reverse(line)*"") + "</tt><br></td></tr>\n";
      }
    }

    buf+= "</table>";
    buf+="</html>";
    
    return buf->get();
  }
  
  void setStatus(string s)
  {
   // werror("%O\n", ui->Status);
    ui->setStatus(s);
    setLineStatus(ribbon?ribbon->current_line:"0");
  }

  void processedCode()
  {
    if(!inManualControl && ribbon)
      ui->updateThermometer(((float)ribbon->current_pos/jobinfo->code_count)*100);
  }

  void setLineStatus(string s)
  {
    ui->setCurrentLine((int)s);
    ui->setLineStatus(s + "/" + jobinfo->line_count);
  }

  void setLineContents(string s)
  {
    ui->setLineContents(s);
  }

  void setCycleStatus(int(0..1) status)
  {
    ui->setCycleIndicator(status);
  }
