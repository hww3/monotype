float basicunit = 0.0007685;

float bigadj = 0.0075;
float smalladj = 0.0005;

float setwidth = 12.0;

int jspacewidth=4;
int lineunits = 180;
array displayline = ({});


int linelength = 0;
int linespaces = 0;
array lines = ({});
array line = ({});

float unitwidth = setwidth * basicunit;
float justspace;
int big, little;

object m;
object n;

int main()
{
  m = MatCaseLayout();                                            
  n = Public.Parser.XML2.parse_xml(Stdio.read_file("Book5A.xml"));
  m->load(n);

  int c;

  Stdio.stdin.tcsetattr((["VMIN":1, "VTIME":0, "ISIG":0, "ICANON":0, "ECHO":0]));

  while(c = Stdio.stdin.getchar())
  {
	if(c == 4) break;
	else if(c == 127) { remove(); }
	else add(c);
  }

 Stdio.stdin.tcsetattr((["VMIN":1, "VTIME":0, "ISIG":0, "ICANON":0, "ECHO":1]));

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
  return 1;
}

void remove()
{
   displayline = displayline[..sizeof(displayline)-2];
   if(line[-1]->is_justifying_space) linespaces--;
   linelength -= line[-1]->get_set_width();
   line = line[0..sizeof(line)-2];	
}

void add (int c)
{
  string activator = String.int2char(c);
  object mat;
  // backspace.
  if(activator == " ")
  {
    displayline += ({" " });
    line += ({JustifyingSpace(jspacewidth)});
    linelength += jspacewidth;
    linespaces ++;
	return;
  }    
  else if(activator == "\n")
  {
    lines += ({Line(line, big, little)});
    line = ({});
    linelength = 0;
    linespaces = 0;
    displayline = ({});
    return;
  }

  mat = m->elements[activator];

  if(!mat) werror("invalid activator " + c + "!\n");
  else
  {
    displayline += ({ activator });
    linelength+=mat->get_set_width();
    line += ({mat});
  }

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

  write("%s %d %s\n", displayline * "", lineunits-linelength, can_justify()?("* "+ big + " " + little):"");
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
