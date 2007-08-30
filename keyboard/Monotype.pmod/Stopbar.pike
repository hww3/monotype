import Public.Parser.XML2;

string name;
string description;
mapping bars = ([]);

void create()
{
 
}

void set_name(string _name)
{
  name = _name;
}

void set_description(string _description)
{
  description = _description;
}

void set(int row, int width)
{
  if(row<1 || row >15)
    error("invalid row provided!\n");
  bars[row] = width;
}

int get(int row)
{
  if(row<1 || row >15)
    error("invalid row provided!\n");
  return bars[row];
}

int load(Node n)
{
  if(n->get_node_name() != "stopbar")
    error("invalid stopbar datafile.\n");

  name = n->get_attributes()["name"];
  description = n->get_attributes()["description"];

  foreach(n->children();; Node c)
  {
    if(c->get_node_type() != Constants.ELEMENT_NODE)
      continue;

    if(c->get_node_name() == "bar")
    {
      set((int)(c->get_attributes()["column"]), (int)(c->get_text()));
    }
  }

  return 1;
}

Node dump()
{
  Node n = new_xml("1.0", "stopbars");
  
  if(name)
    n->set_attribute("name", name);
  if(description)
    n->set_attribute("description", description);

  foreach(bars; mixed i; mixed v)
  {
    Node y = n->new_child("bar", (string)v);
    y->set_attribute("row", (string)i);
  }

  return n;
}
