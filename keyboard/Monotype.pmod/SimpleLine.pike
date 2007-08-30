float basicunit = 0.0007685;

float bigadj = 0.0075;
float smalladj = 0.0005;

float setwidth = 12.0;

int jspacewidth=4;
int lineunits = 540;
array displayline = ({});
int main()

{
  object m = MatCaseLayout();                                            
  object n = Public.Parser.XML2.parse_xml(Stdio.read_file("Book5A.xml"));
  m->load(n);

  int c;
  int linelength = 0;
  int linespaces = 0;
  array lines = ({});
  array line = ({});

  float unitwidth = setwidth * basicunit;
  float justspace;
  int big, little;

  Stdio.stdin.tcsetattr((["VMIN":1, "VTIME":0, "ISIG":0, "ICANON":0, "ECHO":0]));

  while(c = Stdio.stdin.getchar())
  {
    string activator = String.int2char(c);
    object mat;
    if(c == 4)
    {
      foreach(reverse(lines);; object line)
      {
        int ilinelength = 0;
        int ilinespaces = 0;
        // first, we need to generate the wedge positions.
        foreach(reverse(line->elements);; object m)
        {
          if(m->is_justifying_space) ilinespaces ++;
          ilinelength += m->get_set_width();
        }
        float ijustspace;
        int ibig, ilittle;
        if(ilinespaces)
        {
          // algorithm from page 14 of the booklet.
          ijustspace = ((float)(lineunites - ilinelength)/ilinespaces);
          ijustspace = (ijustspace + (jspacewidth - 6) * (unitwidth * 1.537));
        }
        else ijustspace = 0.0;

        int numsteps = (int)ijustspace;
        numsteps += 53;

        int f = ijustspace - (float)(int)ijustspace;
        if((f*2)>1.0) 
          numsteps ++;

        ibig = numsteps / 15;
        ilittle = numsteps % 15;
/*
          ijustspace = ((float)(lineunits-ilinelength)/ilinespaces)* unitwidth;
        else ijustspace = 0.0;
        ibig = (int)floor(ijustspace/bigadj);
        ilittle = (int)floor((ijustspace - (bigadj*ibig))/ smalladj);
*/
        write("0.0005 %d\n", ilittle);
        write("0.0075 %d\n", ibig);
        foreach(reverse(line->elements);; object m)
        {
          if(m->is_justifying_space)
            write("S\n");
          else
            write("  %s %d\n", m->col_pos, m->row_pos);  
        }
          
      }
      break;
    }
    if(c == 127)
    {
      displayline = displayline[..sizeof(displayline)-2];
      if(line[-1]->is_justifying_space) linespaces--;
      linelength -= line[-1]->get_set_width();
      line = line[0..sizeof(line)-2];
  write("%s %d\n", displayline * "", lineunits-linelength);
      
      continue;
    }
    else if(activator == " ")
    {
      displayline += ({" " });
      line += ({JustifyingSpace(jspacewidth)});
      linelength += jspacewidth;
      linespaces ++;
      continue;
    }    
    else if(activator == "\n")
    {
      lines += ({Line(line)});
      line = ({});
      linelength = 0;
      linespaces = 0;
      displayline = ({});
      continue;
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
    justspace = ((float)(lineunits-linelength)/linespaces)* unitwidth;
  else justspace = 0.0;
  big = (int)floor(justspace/bigadj);
  little = (int)floor((justspace - (bigadj*big))/ smalladj);

  write("%s %d %s\n", displayline * "", lineunits-linelength, (linespaces && big<15 && little < 15)?("* "+ big + " " + little):"");

  }

  werror("%d units to justify divided over %d justifying spaces in line: %d %d", 
            lineunits-linelength, linespaces, 
            big, little);

  write("0.0005 %d\n", little);
  write("0.0075 %d\n", big);

  foreach(reverse(line);; object m)
  {
    if(m->is_justifying_space)
      write("S\n");
    else write("%d %s\n", m->row_pos, m->col_pos);
  }

  return 1;
}

class JustifyingSpace(int size)
{
  int get_set_width()
  {
    return size;
  }	

  int is_justifying_space = 1;
}

class Line(array elements)
{

}
