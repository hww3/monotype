// we can set this.

constant MODE_JUSTIFY = 0;
constant MODE_LEFT = 1;
constant MODE_RIGHT = 2;
constant MODE_CENTER = 3;

float setwidth = 12.0;

int currentpos;
int jspacewidth=4;
int lineunits = 180;
array displayline = ({});

int linelength = 0;
int linespaces = 0;
array lines = ({});
array line = ({});

float justspace;
int big, little;

object m;
object n;

int line_mode = MODE_JUSTIFY;

string last = "";

int main(int argc, array argv)
{

  m = load_matcase("Book5A");

  werror("ARGS: %O, %O\n", argc, argv);
  if(argc == 1)
  {
    int c;
    mapping tcattrs;

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
  {
	parse(argv[1]);
  }
  generate_ribbon(lines);

  return 1;
}

void parse(string filename)
{
  string s = Stdio.read_file(filename);

  object parser = Parser.HTML();
  mapping extra = ([]);
  parser->_set_tag_callback(i_parse_tags);
  parser->_set_data_callback(i_parse_data);
  parser->set_extra(extra);

  parser->finish(s);
}

mixed i_parse_data(object parser, string data, mapping extra)
{
	int lastjs = 0;

    data = replace(data, ({"\n", "\r", "\t"}), ({" ", " ", " "}));

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
			werror("removing a character: %O\n", x?(x->activator?x->activator:"JS"):"");
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

mixed i_parse_tags(object parser, string data, mapping extra)
{
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
	  array spaces = ({4, 5, 6, 7, 9, 10, 18});
	  array toadd = ({});

	int left = amount;
	int total = left;

	  foreach(reverse(spaces); int i; int space)
	  {
	     while(left > space)
	     {
			toadd += ({space});
			left -= space;
	     }	
	  }

	//  calculate_justification();
	  werror("to quad out %d, we need the following: %O\n", total, toadd);  
	  foreach(reverse(toadd);;int i)
	  {
	    add("S" + i, atbeginning);	
	  }
	
}

void generate_ribbon(array lines)
{
	foreach(reverse(lines);; object line)
    {
      write("0005 0075 %d\n", line->little);
      write("0075 %d\n", line->big);

      foreach(reverse(line->elements);; object me)
      {
        if(me->is_justifying_space)
        {
	      object x = m->elements["JS"];
          write("S %d %s [%s]\n", x->row_pos, x->col_pos, x->character);
        }
        else write("%d %s [%s]\n", me->row_pos, me->col_pos, me->character);
      }
    }  
}

object load_matcase(string ml)
{
  object m = MatCaseLayout();                                            
  n = Public.Parser.XML2.parse_xml(Stdio.read_file(ml + ".xml"));
  m->load(n);
  return m;
}

object new_line()
{
  lines += ({Line(line, big, little)});
  line = ({});
  linelength = 0;
  linespaces = 0;
  displayline = ({});    
}

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
	if(linespaces)
  {
	// algorithm from page 14
    justspace = ((float)(lineunits-linelength)/linespaces); // in units of set.
  }
  else justspace = 0.0;

  justspace = justspace + (jspacewidth-6);
  justspace *= (setwidth * 1.537);	

  int w = (int)justspace + 53;

  big = w/15;
  little = w%15;
}

void add (string activator, int|void atbeginning)
{
  object mat;
  // backspace.
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

  mat = m->elements[activator];

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

  werror("%s %d %s %s\n", displayline * "", lineunits-linelength, can_justify()?("* "+ big + " " + little):"", is_overset()?(" OVERSET "):"");
}

int is_overset()
{
	return (linelength > lineunits);
}

int can_justify()
{
  	return(linespaces && big<15 && little < 15);
}

class JustifyingSpace(int size)
{
  int get_set_width()
  {
    return size;
  }	

  int is_justifying_space = 1;
}

class Line(array elements, int big, int little)
{

}
