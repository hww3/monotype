import Public.Parser.XML2;

string name;
string description;
int matcase_size;
string wedge;
mapping spaces = ([]);
object justifying_space;

int maxrow = 15;
multiset validcolumns = (<"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", 
        "L", "M", "N", "O">);
// mapping of columns containing a mapping for each row.
mapping matcase = ([]);
mapping elements = ([]);

void create(int|void size)
{
  matcase_size = size;

  switch(size)
  {
	case Monotype.MATCASE_15_15:
	  break;
	case Monotype.MATCASE_15_17:
	  validcolumns += (<"NI", "NL" >);
	  break;
	case Monotype.MATCASE_16_17:
      validcolumns += (<"NI", "NL" >);
	  maxrow = 16;
	  break;
  }
}

void set_name(string _name)
{
  name = _name;
}

void set_description(string _description)
{
  description = _description;
}

void checkValidPosition(string column, int row)
{
	
  if(row<1 || row >maxrow)
    error("invalid row provided!\n");

  if(!validcolumns[column]) 
   error("invalid matrix case position requested.\n");
  
}

void delete(string column, int row)
{
  checkValidPosition(column, row);
  if(!matcase[column]) matcase[column] = ([]);
   m_delete(matcase[column], row);
}

void set(string column, int row, Matrix mat)
{
  checkValidPosition(column, row);

  if(!matcase[column]) matcase[column] = ([]);

  matcase[column][row] = mat;
  mat->set_position(row, column);
  // we prepend the style type (as long as it's not roman) 
  // styles:
  //   R == ROMAN
  //   I == ITALIC
  //   B == BOLD
  //   U == UNDERLINE
  //   S == SMALL CAPS
  if(mat->is_fs || mat->is_js)
  {
    elements["SPACE_"+ mat->set_width] = mat;
    spaces[mat->set_width] = mat;
  }
  if(mat->is_js)
  { 
    elements->JS = mat;
	justifying_space = mat;
  }
  else
    elements[((mat->style && mat->style!="R")?(mat->style+"|"):"") + mat->activator] = mat;

}

void set_size(int size)
{
  matcase_size = size;
  switch(size)
  {
	case Monotype.MATCASE_15_15:
	  break;
	case Monotype.MATCASE_15_17:
	  validcolumns += (<"NI", "NL" >);
	  break;
	case Monotype.MATCASE_16_17:
      validcolumns += (<"NI", "NL" >);
	  maxrow = 16;
	  break;
  }

}

void set_wedge(string w)
{
	wedge = w;
}

Matrix get(string column, int row)
{
  checkValidPosition(column, row);
  return matcase[column][row];
}

int load(Node n)
{
  if(n->get_node_name() != "matcase")
    error("invalid stopbar datafile.\n");

  name = n->get_attributes()["name"];
  description = n->get_attributes()["description"];
  matcase_size = (int)(n->get_attributes()["size"]);


  switch(matcase_size)
  {
	case Monotype.MATCASE_15_15:
	  break;
	case Monotype.MATCASE_15_17:
	  validcolumns += (<"NI", "NL" >);
	  break;
	case Monotype.MATCASE_16_17:
      validcolumns += (<"NI", "NL" >);
	  maxrow = 16;
	  break;
  }

  wedge = n->get_attributes()["wedge"];

  foreach(n->children()||({});; Node c)
  {
    if(c->get_node_type() != Constants.ELEMENT_NODE)
      continue;

    if(c->get_node_name() == "element")
    {
      object m = select_xpath_nodes("matrix", c)[0];
      set(c->get_attributes()["column"],
          (int)(c->get_attributes()["row"]),  
          Matrix(m));
    }
  }

  return 1;
}

Node dump()
{
  Node n = new_xml("1.0", "matcase");
  
  if(name)
    n->set_attribute("name", name);
  if(description)
    n->set_attribute("description", description);

    n->set_attribute("size", (string)matcase_size);
	n->set_attribute("wedge", (string)wedge || "");
  foreach(matcase; mixed i; mixed v)
  {
    foreach(v; mixed in; mixed va)
    {
      Node y = n->new_child("element", "");
      y->set_attribute("row", (string)in);
      y->set_attribute("column", i);
      y->add_child(va->dump());
    }
  }

  return n;
}

class Matrix
{
  string series;
  int size;
  string style;
  string character;
  string activator;
  int set_width;
  int row_pos;
  string col_pos;
  int is_js;
  int is_fs;

  static void create(void|Node n)
  {
   if(n) load(n);
  }

  int load(Node n)
  {
    if(n->get_node_name() != "matrix")
      error("invalid matrix data.\n");
 
    mapping a = n->get_attributes();

	if(a->space && a->space == "fixed") is_fs = 1; 
	else if(a->space && a->space == "justifying") is_js = 1; 
    if(a->series) series = a->series;
    if(a->size) size = (int)(a->size);
    if(a->weight) style = a->weight;
    if(a->character) character = a->character;
    if(a->activator) activator = a->activator;
    if(a->set_width) set_width = (int)(a->set_width);
    return 1;
  }

  Node dump()
  {
    Node n = new_xml("1.0", "matrix");
  
    if(series)
      n->set_attribute("series", series);
    if(size)
      n->set_attribute("size", (string)size);
    if(style)
      n->set_attribute("weight", style);
    if(character)
      n->set_attribute("character", character);
    if(set_width)
      n->set_attribute("set_width", (string)set_width);
     if(is_fs)
        n->set_attribute("space", "fixed");
      else if(is_js)
        n->set_attribute("space", "justifying");
      else if(activator)
        n->set_attribute("activator", activator);
	  
    return n;
  }

  int is_space()
  {
	return is_js || is_fs;
  }

  

  int get_set_width()
  {
    return set_width;
  }

  string get_activator()
  {
    return activator;
  }
  
  string get_character()
  {  
    return character;
  }

  string get_style()
  { 
    return style;
  }
  
  int get_size()
  {
    return size;
  }
  
  string get_series()
  {
    return series;
  }

  void set_set_width(int w)
  {
    set_width = w;
  }

  void set_activator(string a)
  {
    activator = a;
  }
  
  void set_character(string c)
  {  
    character = c;
  }

  void set_style(string s)
  { 
    style = s;
  }
  
  void set_size(int s)
  {
    size = s;
  }
  
  void set_series(string s)
  {
    series = s;
  }

  void set_position(int row, string col)
  {
    row_pos = row;
    col_pos = col; 
  }
} 
