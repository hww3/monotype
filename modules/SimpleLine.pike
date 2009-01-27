
int do_help(array argv)
{
  werror("Usage: %s [-m|--matcase matcase] [-s|--stopbar stopbar] "
 "[-w|--setwidth setwidth] [-M|--mould mouldsize] [--help] "
 "[inputfile] [outputfile]\n");
}

int main(int argc, array argv)
{
  mapping settings = ([]);

  // parse each command line argument
  foreach(Getopt.find_all_options(argv,aggregate(
	    ({"stopbar",Getopt.HAS_ARG,({"-s", "--stopbar"}) }),
	    ({"output",Getopt.HAS_ARG,({"-o", "--output"}) }),
	    ({"matcase",Getopt.HAS_ARG,({"-m", "--matcase"}) }),
	    ({"set",Getopt.NO_ARG,({"-w", "--setwidth"}) }),
	    ({"linelength",Getopt.NO_ARG,({"-l", "--linelength"}) }),
	    ({"mould",Getopt.NO_ARG,({"-M", "--mould"}) }),
	    ({"help",Getopt.NO_ARG,({"-h", "--help"}) }),
	    )),array opt)
	{
		switch(opt[0])
		{
			case "output":
			  settings->outputfile = opt[1];
			  break;
			case "stopbar":
			  settings->stopbar = opt[1];
			  break;
			case "set":
			  settings->setwidth = (float)opt[1];
			  break;
			case "mould":
			  settings->mould = (int)opt[1];
			  break;
			case "linelength":
			  settings->linelengthp = (float)opt[1];
			  break;
			case "matcase":
			  settings->matcase = opt[1];
			  break;
			case "help":
			  return do_help(argv);
			  break;
			default:
			  werror("unknown option " + opt[0] + "\n.");
			  exit(1);
			  break;
		}
	}		

  argv = argv - ({0});

  // calculate the total number of units a line should occupy.
  int lineunits = (int)(18 * (1/(settings->setwidth/12.0)) * settings->linelengthp);

  werror("Input File: %s\n", settings->filename);
  werror("Output File: %s\n", settings->outputfile);
  werror("Matcase: %s\n", settings->matcase);
  werror("Stopbar: %s\n", settings->stopbar);
  werror("Set Width: %s\n", (string)(settings->setwidth));
  werror("Line Length: %.2f picas / %.2f ems / %d units\n", settings->linelengthp, lineunits/18.0, lineunits);

  // if we haven't specified an input file, we should use interactive mode
  // this code may have decayed somewhat.
/*
  if(sizeof(argv) == 1)
  {
    int c;
    mapping tcattrs;

	interactive = 1;
	if(outputfile == "-")
      file = Stdio.File("stdout", "cwrt");
	else
      file = Stdio.File(outputfile, "cwrt");
    filename = "interactive input";
    // turn echo off and enable single character reads.
    tcattrs = Stdio.stdin.tcgetattr();
    
    Stdio.stdin.tcsetattr((["VMIN":1, "VTIME":0, "ISIG":0, "ICANON":0, "ECHO":0]));

   // let's input some data.
    while(c = Stdio.stdin.getchar())
    {
	  if(c == 4) break;
	  else if(c == 127) remove();
	  else add(String.int2char(c));
    }
  
    Stdio.stdin.tcsetattr(tcattrs);
  }
  else 
*/
object g = Monotype.Generator(settings);
  // otherwise, we read the file and parse it.
  {
	//werror("%O\n", argv);
	settings->filename = argv[1];
	g->parse(argv[1]);
  }

  // finally, generate the ribbon!
  g->generate_ribbon(settings->outputfile);

  return 0;
}

