inherit "Plugin";

// delay in microseconds (1000us = 1ms)

object iow;
object driver;


int cv;
int state;
int started = 0;
int last_changed = 0;

// this should be the bit attached to the single input from the caster.
// note that this value could vary depending on how you've wired your 
// interconnect cables
int interesting_bits = 33554432;

mapping pincodes;

array codes = ({
	"N",
	"M",
	"L",
	"K",
	"J",
	"I",
	"H",
	"G",
	"F",
	"S",
	"E",
	"D",
	"0075",
	"C",
	"B",
	"A",
	"1",
	"2",
	"3",
	"4",
	"6",
	"5",
	"7",
	"8",
	"9",
	"10",
	"11",
	"12",
	"13",
	"14",
	"0005"	
});

// the makeup of this array could potentially be different based on
// how you've wired your cabling. it's not terribly elegant, but 
// does provide a simple way to account for human error in building 
// the interface cables.
array pinmap = ({ /* 31 elements */
    8388608,
    2097152,
    524288,
    131072,
    2147483648,
    536870912,
    134217728,
    128,
    32,
    8,
    2,
    32768,
    8192,
    2048,
    512,
    16777216,
    67108864,
    268435456,
    1073741824,
    65536,
    1048576,
    262144,
    4194304,
    256,
    1024,
    4096,
    16384,
    1,
    4,
    16,
    64
});

// this function is called when the usb interface reports a change in status 
// of one of its io pins.
void report_callback(mixed ... args)
{
  int nv;
//werror("args: %O\n", args);
  sscanf(args[0], "%04c", nv);
//werror("callback: %O\n", nv);
  nv = nv & interesting_bits;
  if(nv != cv)
  {
    if((last_changed + (driver->CycleSensorDebounce * 10000)) < (last_changed = gethrtime()))
    {
      value_changed(nv);
    }
    cv = nv;
  }
}

void value_changed(int nv)
{
//  write(nv + "\n");
// we'd want to flip the action if we have a permanently attached sensor.
//if(!driver->ui->CycleSensorMode)

  if(nv&interesting_bits)
  {
	if(!driver->ui->CycleSensorMode)
		doStart();
	else
		doEnd();
  }
  else
  {
	if(!driver->ui->CycleSensorMode)
	  doEnd(); 
	else
	  doStart();
  }
}

void doStart()
{
	state = 1;
	driver->setCycleStatus(1);
//	write("on: %O\n", started); 

	if(driver->forced) return 0;

	if(started)
	  start_code();
	else
	  end_code();
}

void doEnd()
{
	state = 0;
	driver->setCycleStatus(0);
	//write("off\n");
	if(started)
  	  end_code();	
}

void start_code()
{
  array code_str = driver->getNextCode();

//werror("***\n*** code: %O\n***\n", code_str);

  if(!code_str)
  {
  	driver->codesEnded();
	  driver->doStop();
	  driver->rewindRibbon();
	  driver->setStatus("End of Ribbon.");
	return 0;
  }

  do_start_code(code_str);
}

void do_start_code(array code_str)
{
  send_code_to_interface(code_str);
  
  driver->setStatus((code_str*"-"));

  driver->processedCode();
}

void end_code()
{
  int code;
  code = interesting_bits;	
  iow->write_interface0(sprintf("%04c", code));
//werror("wrote data1.\n");
}

void send_code_to_interface(array code_str)
{
  int code = map_code_to_pins(code_str);
  //werror("writing code %032b\n", code); 
  iow->write_interface0(sprintf("%04c", code));
//werror("wrote data2.\n");
}

static void create(object driver, mapping config)
{
  ::create(driver, config);
	
  pincodes = mkmapping(codes, pinmap);

  iow = Public.IO.IOWarrior.IOWarrior();

  iow->count_interfaces();

  // shut everything off initially.
  iow->write_interface0(sprintf("%04c", 0));
  //werror("wrote data.\n");

  iow->set_report_callback(report_callback, 0);
//werror("done.\n");
//  Public.ObjectiveC.add_backend_runloop();
}

int map_code_to_pins(array codes)
{
  int code = 0;
	
  foreach(codes;;string c)
  {
	code = code | pincodes[c];
  }

  return code;
}

void start()
{
	werror("start()\n");
	started = 1;
}

void stop()
{
	werror("stop()\n");
	started = 0;
}

