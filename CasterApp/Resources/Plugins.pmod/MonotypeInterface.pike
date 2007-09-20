inherit "Plugin";

object iow;
object driver;

int cv;
int state;
int interesting_bits = 0b00000000100000000000000000000000;

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
	"5",
	"6",
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
    262144,
    1048576,
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

void report_callback(mixed ... args)
{
  int nv;

  sscanf(args[0], "%04c", nv);

  nv = nv & interesting_bits;
  if(nv != cv)
  {

    value_changed(nv);
    cv = nv;
  }
}

void value_changed(int nv)
{
//  write(nv + "\n");
  if(nv&interesting_bits)
  {
	state = 1;
	write("on\n"); 
	start_code();
  }
  else
  { 
	state = 0;
	write("off\n");
	end_code();
  }
}

void start_code()
{
  array code_str = driver->getNextCode();

  if(!code_str)
  {
	driver->codesEnded();
	return;
  }
  int code = map_code_to_pins(code_str);
 
  iow->write_interface(0, sprintf("%04c", code));
}

void end_code()
{
  code = interesting_bits;	
  iow->write_interface(0, sprintf("%04c", code));
}

static void create(object driver, mapping config)
{
  ::create(driver, config);
	
  pincodes = mkmapping(codes, pinmap);

  iow = Public.IO.IOWarrior.IOWarrior();
  iow->count_interfaces();

  iow->set_report_callback(report_callback, 0);
  Public.ObjectiveC.add_backend_runloop();
}

int map_code_to_pins(array codes)
{
  int code = 0;
	
  foreach(codes;;string c)
  {
	code = code | pinmap[c];
  }

  return code;
}