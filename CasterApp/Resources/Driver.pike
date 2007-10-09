import Public.ObjectiveC;

  object plugin;
  object ribbon;
  object ui;
  mapping jobinfo;

  array getNextCode()
  {
	return ribbon->get_next_code();
  }

  void stop()
  {
    plugin->stop();		
  }

  void start()
  {
	plugin->start();
  }

  void forwardLine()
  {
	ribbon->skip_to_line_end();
  }

  void backwardLine()
  {
	ribbon->skip_to_line_beginning();
	processedCode();
  }

  void codesEnded()
  {
	
  }
  
  void rewindRibbon()
  {
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
	ui->Status->setStringValue_(s);
  }

  void processedCode()
  {
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