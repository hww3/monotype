constant MATCASE_15_15 = 0;
constant MATCASE_15_17 = 1;
constant MATCASE_16_17 = 2;

constant MODIFIER_ITALICS = 1;
constant MODIFIER_BOLD = 2;
constant MODIFIER_SMALLCAPS = 4;

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
object load_stopbar_string(string ml)
{
  object m = master()->resolv("Monotype.Stopbar")();                                            
//  werror("Loading stopbar from " + ml + ".xml\n");
  object n = Public.Parser.XML2.parse_xml(ml);
  m->load(n);
  return m;
}
