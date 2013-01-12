inherit "Plugin";

mixed call_out_id;

void start()
{
//	throw(Error.Generic("aiiee"));
	call_out_id = call_out(process_code, 0.1);
}

void stop()
{
	remove_call_out(call_out_id);
}

void do_start_code(array code_str)
{
	
}

void process_code()
{
	array code = driver->getNextCode();
	if(!code) 
	{
	  driver->doStop();
	  driver->rewindRibbon();
  	  driver->setStatus("End of Ribbon.");
	  return;
	}
	driver->setStatus((code*"-"));
	driver->processedCode();
	driver->setCycleStatus(1);
	call_out_id = call_out(stop_code, 0.375);
}

void stop_code()
{
	driver->setCycleStatus(0);
	call_out_id = call_out(process_code, 0.375);

}
