
// some modes we find useful
constant MODE_JUSTIFY = 0;
constant MODE_LEFT = 1;
constant MODE_RIGHT = 2;
constant MODE_CENTER = 3;

float setwidth = 10.0;
string matcase = "Bulmer - 462 EFG [chestnut 10]";
string stopbar = "S5";
string filename = "[interactive input]";
string outputfile = "[interactive input].rib";
int currentpos;
int jspacewidth=4;
int lineunits = 0;
int interactive = 0;
array displayline = ({});

// line length in picas
float linelengthp = 30.0;
int linelength = 0;
int linespaces = 0;
array lines = ({});
array line = ({});

int mould = 12;

float justspace;
int big, little;

//! the output file object
object file;

//! the matcase and stopbar objects
object m;
object s;

int isitalic = 0;
int issmallcaps = 0;

int line_mode = MODE_JUSTIFY;

string last = "";

int do_help(array argv)
{
  werror("Usage: %s [-m|--matcase matcase] [-s|--stopbar stopbar] "
 "[-w|--setwidth setwidth] [-M|--mould mouldsize] [--help] "
 "[inputfile] [outputfile]\n");
}

int main(int argc, array argv)
{
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
			  outputfile = opt[1];
			  break;
			case "stopbar":
			  stopbar = opt[1];
			  break;
			case "set":
			  setwidth = (float)opt[1];
			  break;
			case "mould":
			  mould = (int)opt[1];
			  break;
			case "linelength":
			  linelengthp = (float)opt[1];
			  break;
			case "matcase":
			  matcase = opt[1];
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
  lineunits = (int)(18 * (1/(setwidth/12.0)) * linelengthp);

  werror("Input File: %s\n", filename);
  werror("Output File: %s\n", outputfile);
  werror("Matcase: %s\n", matcase);
  werror("Stopbar: %s\n", stopbar);
  werror("Set Width: %s\n", (string)setwidth);
  werror("Line Length: %.2f picas / %.2f ems / %d units\n", linelengthp, lineunits/18.0, lineunits);

  m = load_matcase(matcase);
  s = load_stopbar(stopbar);

  // if we haven't specified an input file, we should use interactive mode
  // this code may have decayed somewhat.
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
  else // otherwise, we read the file and parse it.
  {
	//werror("%O\n", argv);
	filename = argv[1];
	parse(argv[1], outputfile);
  }

  // finally, generate the ribbon!
  generate_ribbon(lines);

  return 0;
}

void parse(string filename, string|void output)
{
  string s = Stdio.read_file(filename);
  s = utf8_to_string(s);

  if(output != "-")
  {
    werror("*** writing output to ribbon " + output + "\n");
    file = Stdio.File(output, "crwt");
  }
  else
  {
    werror("*** writing output to stdout\n");
    file = Stdio.File("stdout");
  }

  object parser = Parser.HTML();
  mapping extra = ([]);
  parser->_set_tag_callback(i_parse_tags);
  parser->_set_data_callback(i_parse_data);
  parser->set_extra(extra);


  // feed the data to the parser and have it do its thing.
  parser->finish(s);
}

mixed i_parse_data(object parser, string data, mapping extra)
{
	int lastjs = 0;

    string xdata = replace(data, ({"\r", "\t"}), ({" ", " "}));

//werror("* xdata: %O\n", xdata);
 
    foreach(xdata/"\n";; data)
    {
      data = ((data / " ") - ({""})) * " ";

  	  for(int i = 0; i<sizeof(data) ;i++)
	  {
	   if(data[i] == ' ')
	     lastjs = i;
	   add(String.int2char(data[i]));
	   if(is_overset()) // back up to before the last space.
	   {
		  for(int j = i; j >= lastjs; j--)
		  {
			object x = remove();
			// werror("removing a character: %O\n", x?(x->activator?x->activator:"JS"):"");
		  }
		  if(line_mode)
		  {
			quad_out();
		  }
		  new_line();
		  i = lastjs;
	   }
	}
  }
}

mixed i_parse_tags(object parser, string data, mapping extra)
{
	if(data == "<i>")
	{
		isitalic ++;
	}
	if(data == "</i>")
	{
		isitalic --;
		if(isitalic < 0) isitalic = 0;
	}
      if(data == "<sc>")
      {
              issmallcaps ++;
      }
      if(data == "</sc>")
      {
              issmallcaps --;
              if(issmallcaps < 0) issmallcaps = 0;
      }
	if(data == "<left>")
	{
		line_mode = MODE_LEFT;
	}
	if(data == "<center>")
	{
		line_mode = MODE_CENTER;
	}
	if(data == "<right>")
	{
		line_mode = MODE_RIGHT;
	}
	if(data == "<justify>")
	{
		line_mode = MODE_JUSTIFY;
	}
	else if(data == "<qo>")
	{
	  quad_out();
	  new_line();
    }
	else if(data == "<p>")
	{
	  if(!can_justify())
        quad_out();
	  new_line();
    }
    else if(Regexp.SimpleRegexp("<[sS][0-9]*>")->match(data))
	{
		add(data[1..sizeof(data)-2]);
		if(is_overset())
		{
			werror("Fixed space (%d unit) won't fit on line... dropping.\n");
		}
	}
}

// fill out the line according to the justification method (left/right/etc)
void quad_out()
{
  int left = lineunits - linelength;
//werror("* have %d left on line.\n", left);

  if(line_mode == MODE_LEFT || line_mode == MODE_JUSTIFY)
  {
	low_quad_out(left);
  }
  else if(line_mode == MODE_RIGHT)
  {
    low_quad_out(left, 1);	
  }
  else if(line_mode == MODE_CENTER)
  {
     int l,r;
     l = left/2;
     r = (left/2) + (left %2);
	 low_quad_out(r);
	 low_quad_out(l, 1);
  }
}

void low_quad_out(int amount, int|void atbeginning)
{
	  array toadd = ({});

	toadd = findspace()->simple_find_space(amount, m->spaces);
//	werror("spaces: %O, %O\n", amount, toadd);
	if(!toadd)
  	  toadd = simple_find_space(amount, m->spaces);
      toadd = sort(toadd);
	//  calculate_justification();
	//  werror("to quad out %d, we need the following: %O\n", total, toadd);  
	  foreach(toadd;;int i)
	  {
	    add("SPACE_" + i, atbeginning);	
	  }
	
}

// this an inferior quad-out mechanism. we currently favor
// the algorithm in findspace.pike. left here for historical
// completeness.
array simple_find_space(int amount, mapping spaces)
{
	int left = amount;
	int total = left;

	array toadd = ({});

  foreach(reverse(indices(spaces)); int i; int space)
  {
   while(left > space)
   {
		toadd += ({space});
		left -= space;
   }	
  }

 return toadd;
}

// actually generates the ribbon file from an array of lines of sorts.
// line justifications should already be calculated and provided with each 
// line, however, each sort is checked to make sure its requested width is
// the same as the width of the wedge in the same position. if it's not, 
// we can use various methods (currently consisting only of using the 
// space justification wedges) to "nudge" character to the right width, 
// ensuring justification and world peace.
void generate_ribbon(array lines)
{
	int f,c;
        werror("*** writing %d lines to the ribbon\n", sizeof(lines));
	
	file->write("name: %s\n", filename); 
	file->write("face: %s\n", matcase);
	file->write("set: %.2f\n", setwidth);
	file->write("wedge: %s\n", stopbar);
	file->write("mould: %d\n", mould);
	file->write("linelength: %.2f\n", linelengthp);
	file->write("\n");
	
	foreach(reverse(lines);; object line)
        {
          // a little nomenclature here: c == coarse (0075) f == fine (0005), 
          //   cc == current coarse setting, cf == current fine setting
	  int cc, cf; // the current justification wedge settings
	  f = line->little;
	  c = line->big;
	  cf = f;
	  cc = c;
	  write("\n");
          file->write("0005 0075 %d\n", f);
          file->write("0075 %d\n", c);

          foreach(reverse(line->elements);; object me)
          {
	    int needs_adjustment;
	
            if(me->is_justifying_space)
            {
              // if we've previously changed the justification wedges in order to
              // correct a sort width, we need to put things back.
	      if(cf != f || cc != c)
	      {
		werror("resetting justification wedges.\n");
		      file->write("0005 %d\n", f);
		      file->write("0075 %d\n", c);
			  cf = f;
			  cc = c;
	      }
	      object me = m->elements["JS"];
              // houston, we have a problem!
	      if(!me) error("No Justifying Space!\n");
              file->write("S %d %s [ ]\n", me->row_pos, me->col_pos);
              werror("_");
            }
            else 
	    {
	      int wedgewidth = s->get(me->row_pos);
	
	      //werror("want %d, wedge provides %d\n", mat->get_set_width(), wedgewidth);
	      if(wedgewidth != me->get_set_width()) // we need to adjust the justification wedges
	      {
	        int nf, nc;
		werror("needs adjustment: have %d, need %d!\n", wedgewidth, me->get_set_width());
		needs_adjustment = 1;
	        // first, we should calculate what difference we need, in units of set.
	        int neededunits = me->get_set_width() - wedgewidth;
			  
	        // then, figure out what that adjustment is in terms of 0075 and 0005
                [nc, nf] = calculate_wordspacing_code(neededunits);
		// if it's not what we have now, make the adjustment
		if(cf != nf || cc != nc)
		{

                  file->write("0005 %d\n", nf);
	          file->write("0075 %d\n", nc);
                  cf = nf;
		  cc = nc;
	        }
	      }
			
	      if(needs_adjustment)
	        file->write("S ");
              werror(string_to_utf8(me->character));			
	      file->write("%d %s [%s]\n", me->row_pos, me->col_pos, string_to_utf8(me->character));
	   }
       }
    }  

  file->write("0075 0005 1\n"); // stop the pump, eject the line.
}

object load_matcase(string ml)
{
  Monotype.MatCaseLayout m;
  
  catch(m = Monotype.load_matcase(ml));
  if(!m) 
  {
     exit(1, "Error: Unable to load matcase " + ml + "\n");
  }

  werror("Spaces in matcase: [ %{%d %}]\n", indices(m->spaces));
  return m;
}

object load_stopbar(string ml)
{
  Monotype.Stopbar s;
  catch(s = Monotype.load_stopbar(ml));
  if(!s) 
  {
     exit(1, "Error: Unable to load stopbar " + ml + "\n");
  }
 
  return s;
}

// add the current line to the job, if it's justifyable.
object new_line()
{
  if(!linespaces && linelength != lineunits) throw(Error.Generic(sprintf("Off-length line: expected %d, got %d\n", lineunits, linelength)));
  else if(linespaces && !can_justify()) throw(Error.Generic(sprintf("Bad Justification: %d %d\n", big, little)));
  
  foreach(line;;object l)
    werror(string_to_utf8(l&&l->character?l->character:" "));
   werror("\n");
  lines += ({Line(line, big, little)});
  line = ({});
  linelength = 0;
  linespaces = 0;
  displayline = ({});    
}

// remove a sort from the line; recalculate the justification
object remove()
{
   displayline = displayline[..sizeof(displayline)-2];
   if(line[-1]->is_justifying_space) linespaces--;
   linelength -= line[-1]->get_set_width();

   object r = line[-1];
   line = line[0..sizeof(line)-2];	

   calculate_justification();

   return r;
}

void calculate_justification()
{
  float justspace;
  if(linespaces)
  {
	// algorithm from page 14
    justspace = ((float)(lineunits-linelength)/linespaces); // in units of set.
  }
  else justspace = 0.0;

  [big, little] = low_calculate_justification(justspace, jspacewidth);
}

array low_calculate_justification(float justspace, int jspacewidth)
{
  justspace = justspace + (jspacewidth-6);
  justspace *= (setwidth * 1.537);	

  int w = ((int)round(justspace)) + 53;

  return ({ w/15, w%15 });
}

// calculates the large (0.0075) and small (0.0005) justification settings
// required to add units to the current sort.
array calculate_wordspacing_code(int units)
{
	// algorithm from page 25
	int steps = (int)round((0.0007685 * setwidth * units) / 0.0005);
	steps += 53;
	return ({steps/15, steps%15});
}

// add a sort to the current line
void add (string activator, int|void atbeginning)
{
  object mat;

  // justifying space
  if(activator == " ")
  {
	if(atbeginning)
	{
		displayline = ({" "}) + displayline;
		line = ({JustifyingSpace(jspacewidth)}) + line;
	}
	else
	{
	    displayline += ({" " });
	    line += ({JustifyingSpace(jspacewidth)});		
	}
    linelength += jspacewidth;
    linespaces ++;
	return;
  }    
  else if(activator == "\n")
  {
	new_line();
    return;
  }

  string code = activator;
  if(isitalic)
      code = "I|" + code;
  else if(issmallcaps)
      code = "S|" + code;

  mat = m->elements[code];

  if(!mat) werror("invalid activator " + activator + "!\n");
  else
  {	
	if(atbeginning)
	{
		displayline = ({activator}) + displayline;
		line = ({mat}) + line;
	}
	else
	{
	    displayline += ({ activator });
	    line += ({mat});		
	}
    linelength+=mat->get_set_width();
  }

  calculate_justification();
  if(interactive)
    werror("%s %d %s %s\n", displayline * "", lineunits-linelength, can_justify()?("* "+ big + " " + little):"", is_overset()?(" OVERSET "):"");
}

int is_overset()
{
	return (linelength > lineunits);
}

int can_justify()
{
//	werror("linespaces: %O big: %O little: %O\n", linespaces, big, little);
  	return(linespaces && (big < 15) && (little < 15));
}

class JustifyingSpace(int size)
{
  int get_set_width()
  {
    return size;
  }	

  int is_justifying_space = 1;
}

// represents a line in a job.
// big and little are the calculated justification settings
class Line(array elements, int big, int little)
{

}
