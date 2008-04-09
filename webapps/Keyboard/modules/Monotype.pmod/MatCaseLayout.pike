import Public.Parser.XML2;

string name;
string description;

// mapping of columns containing a mapping for each row.
mapping matcase = ([]);
mapping elements = ([]);

void create()
{
 
}

mixed `[](mixed a)
{
	return matcase[a];
}

void set_name(string _name)
{
  name = _name;
}

void set_description(string _description)
{
  description = _description;
}

void set(string column, int row, Matrix mat)
{
  if(row<1 || row >15)
    error("invalid row provided!\n");

  if(!(<"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", 
        "L", "M", "N", "O", "NI", "NL">)[column]) 
   error("invalid matrix case position requested.\n");

  if(!matcase[column]) matcase[column] = ([]);

  matcase[column][row] = mat;
  mat->set_position(row, column);
  elements[(mat->style?(mat->style+"|"):"") + mat->activator] = mat;
}

int get(string column, int row)
{
  if(row<1 || row >15)
    error("invalid row provided!\n");
  return matcase[column][row];
}

int load(Node n)
{
  if(n->get_node_name() != "matcase")
    error("invalid stopbar datafile.\n");

  name = n->get_attributes()["name"];
  description = n->get_attributes()["description"];

  foreach(n->children();; Node c)
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

  foreach(matcase; mixed i; mixed v)
  {
    foreach(v; mixed in; mixed va)
    {
      Node y = n->new_child("", "element");
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

  mixed cast(string t)
  {
//	if(t == "string")
	{
	  return "Mat:" + character;
	}
  }

  static void create(void|Node n)
  {
   if(n) load(n);
  }

  int load(Node n)
  {
    if(n->get_node_name() != "matrix")
      error("invalid matrix data.\n");
 
    mapping a = n->get_attributes();

    if(a->series) series = a->series;
    if(a->size) size = (int)(a->size);
    if(a->style) style = a->style;
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
      n->set_attribute("style", style);
    if(character)
      n->set_attribute("character", character);
    if(activator)
      n->set_attribute("activator", activator);
    if(set_width)
      n->set_attribute("set_width", (string)set_width);

    return n;
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
