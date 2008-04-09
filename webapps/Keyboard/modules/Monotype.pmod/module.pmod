//!
object load_matcase(string ml)
{
  object m = .MatCaseLayout();                                            
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
  object m = .Stopbar();                                            
  object n = Public.Parser.XML2.parse_xml(Stdio.read_file(ml + ".xml"));
  m->load(n);
  return m;
}