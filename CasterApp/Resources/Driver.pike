
  object plugin;
  object ribbon;

  array getNextCode()
  {
	
  }

  void stop()
  {
		
  }

  void start()
  {
	
  }

  void forwardLine()
  {
	
  }

  void backwardLine()
  {
	
  }

  mapping loadRibbon(string filename)
  {
     ribbon = ((program)"Ribbon")(filename);

     mapping jobinfo = ribbon->get_info();

     return jobinfo;
  }
