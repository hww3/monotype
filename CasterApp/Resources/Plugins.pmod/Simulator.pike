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
  	  driver->setStatus("at end of ribbon.");
	  return;
	}
	driver->setStatus((code*"-") + ".");
	call_out_id = call_out(process_code, 0.07);
}