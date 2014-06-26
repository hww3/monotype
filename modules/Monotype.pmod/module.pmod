constant MATCASE_15_15 = 0;
constant MATCASE_15_17 = 1;
constant MATCASE_16_17 = 2;

constant MODIFIER_ROMAN = 0;
constant MODIFIER_ITALICS = 1;
constant MODIFIER_BOLD = 2;
constant MODIFIER_SMALLCAPS = 4;

constant version = "2.4.3";

//!
object load_matcase(string ml)
{
  object m = master()->resolv("Monotype.MatCaseLayout")();                                            
  werror("Loading matcase from " + ml + ".xml\n");
  object n = Public.Parser.XML2.parse_xml(Stdio.read_file(ml + ".xml"));
  m->load(n);

/*  for(int x = 3; x < 23; x++)
  {
    if(m->elements["S" + x])
      spaces += ({x});
  }
  werror("Spaces in matcase: [ %{%d %}]\n", spaces);
*/
  return m;
}

//!
object load_stopbar(string ml)
{
  object m = master()->resolv("Monotype.Stopbar")();                                            
  werror("Loading stopbar from " + ml + ".xml\n");
  object n = Public.Parser.XML2.parse_xml(Stdio.read_file(ml + ".xml"));
  m->load(n);
  return m;
}

//!
object load_matcase_string(string ml)
{
  object m = master()->resolv("Monotype.MatCaseLayout")();                                            
//  werror("Loading matcase from " + ml + ".xml\n");
  object n = Public.Parser.XML2.parse_xml(ml);
  m->load(n);

/*  for(int x = 3; x < 23; x++)
  {
    if(m->elements["S" + x])
      spaces += ({x});
  }
  werror("Spaces in matcase: [ %{%d %}]\n", spaces);
*/
  return m;
}

//!
mapping load_font_scheme_string(string fss)
{
  mapping m = Standards.JSON.decode(fss);
  if(!m->definition || !m->name) return 0;
  return m;
}

//!
object load_stopbar_string(string ml)
{
  object m = master()->resolv("Monotype.Stopbar")();                                            
//  werror("Loading stopbar from " + ml + ".xml\n");
  object n = Public.Parser.XML2.parse_xml(ml);
  m->load(n);
  return m;
}

Monotype.Generator split_column(Monotype.Generator g)
{
  // TODO: turn off any page length related settings in the generator.

  // first, calculate the split location.
  float fullpoint = g->lines[0]->lineunits;
  int halfpoint = (int)ceil((float)fullpoint/2);
  float maxf, maxl;
  float minf = (float)fullpoint, minl = (float)fullpoint;
  Monotype.Generator f, b;
  werror("half point is %O\n", halfpoint);
  int offset, pad, w;
  
  object stopbar = g->s;
  for(int i = 1; i < 16; i++)
    if((w = stopbar->get(i)) > offset)
      offset = w;
   if(!offset) throw(Error.Generic("unable to find largest width from stopbar.\n"));
 
   offset = offset%2?(offset/2)+1:(offset/2); 
   pad = offset + sort(indices(g->spaces))[0];

   b = Monotype.Generator(g->config + (["min_little": 7, "min_big": 1, "linelengthp": 0, "lineunits": halfpoint + pad]));
   f = Monotype.Generator(g->config + (["min_little": 7, "min_big": 1, "linelengthp": 0, "lineunits": halfpoint + pad ]));

  foreach(g->lines;;object line)
  {
    object q = Monotype.PositionFinder();
    array x = q->calculate_positions(line);
    float lastpos; 
    int broken = 0;

    foreach(x;int x1;float p)
    {
      if(p<=halfpoint + offset) // split the offset (really should be calculated for each MCA) to get equally sized halves.
      {
        lastpos = p;
      }
      else if(!broken)
      {          
        broken = 1;
        float front, back;
        front = lastpos;
        back = fullpoint - lastpos;
        if(lastpos > maxf) maxf = front;
        if(lastpos <= minf) minf = front;
        if((fullpoint - lastpos) > maxl) maxl = (back);
        if((fullpoint - lastpos) <= minl) minl = (back);
        float toaddf, toaddb;
        toaddf = (halfpoint + pad) - front;
        toaddb = (halfpoint + pad) - back;

        f->make_new_line();  

        int q;
        for(q = 0; q < x1; q++)
        {
          f->current_line->add(line->elements[q]);
        }
        f->low_quad_out(toaddf); 

        b->make_new_line();   

        for(q = x1; q < sizeof(line->elements); q++)
        {
          b->current_line->add(line->elements[q]); 
        }
        b->low_quad_out(toaddb); 

        string code = sprintf("%O/%O", line->big, line->little);
        string fcode = sprintf("%O/%O", f->current_line->big, f->current_line->little);
        string bcode = sprintf("%O/%O", b->current_line->big, b->current_line->little);
  
        if(f->current_line->linespaces && fcode != code)
        {
          display_error(f, b, line, code, bcode, fcode);
          line->errors->append("Expected justification code " + code + ", got " + fcode);
        }
        else if(b->current_line->linespaces && bcode != code)
        {
          display_error(f, b, line, code, bcode, fcode);
          line->errors->append("Expected justification code " + code + ", got " + bcode);
        }
      }
    }
  }
  f->make_new_line();  
  b->make_new_line();  
//  f->lines += b->lines;
  return f;
}

void display_error(object f, object b, object l, string code, string bcode, string fcode)
{
  werror("%O: %O (%O), %O, (%O)\n", code, fcode, f->current_line->linespaces, bcode, b->current_line->linespaces); 
  werror("%O\n", l->elements);
  werror("%O\n", f->current_line->elements);
  werror("%O\n", b->current_line->elements);
  werror("%O\n", l->linelength);
  werror("%O %O %O %O\n", f->current_line->lineunits, f->current_line->linespaces, f->current_line->linelength, f->current_line->calculate_justification());
  werror("%O %O %O %O\n", b->current_line->lineunits, b->current_line->linespaces, b->current_line->linelength, b->current_line->calculate_justification());
}
