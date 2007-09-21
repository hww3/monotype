
  object plugin;
  object ribbon;
  object ui;

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
	
  }

  void backwardLine()
  {
	
  }

  void codesEnded()
  {
	
  }
  
  void rewindRibbon()
  {
	ribbon->rewind(-1);
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

  mapping loadRibbon(string filename)
  {
     ribbon = ((program)"Ribbon")(filename);

     mapping jobinfo = ribbon->get_info();
     setStatus("loaded ribbon.");
     return jobinfo;
  }

  static void create(object _ui, mapping config)
  {
	plugin = ((program)"Plugins.pmod/Simulator")(this, config);
	ui = _ui;
  }