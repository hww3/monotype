inherit "Plugin";

int call_out_id;

void start()
{
//	throw(Error.Generic("aiiee"));
	call_out_id = call_out(process_code, 0.1);
}

void stop()
{
	remove_call_out(call_out_id);
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
	call_out_id = call_out(process_code, 0.75);
}