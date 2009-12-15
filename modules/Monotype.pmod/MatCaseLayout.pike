import Public.Parser.XML2;
import Monotype;
array problems = ({});
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
  else if(!mat->is_fs)
  {
    string key =((mat->style && sizeof(mat->style) && mat->style!="R")?(mat->style+"|"):"") + mat->activator;
    if(elements[key]) 
    { 
       string key2 = activator;
       switch(mat->style)
       {
          case "I":
            key2 = "Italic " + key2;
            break;

          case "S":
            key2 = "SmallCap " + key2;
            break;

          case "B":
            key2 = "Bold " + key2;
            break;

          default:
            key2 = "Roman " + key2;
            break;
       }

       add_problem(column, row, sprintf("Matcase contains duplicate mat: " + key2 + ":new %s %d, orig %s %d\n", 
	    column, row, elements[key]->col_pos, elements[key]->row_pos));
    }
    elements[key] = mat;
  if(mat->style =="R" && mat->character == "0")
  { 
    werror("loaded %s: %O\n", key, (mapping)mat);
  }

  }
}

private void add_problem(string column, int row, string desc)
{
       problems += ({ ({column, row, desc}) });
       werror(desc);
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

array get_ligatures()
{
	array ligatures = ({});
	
	foreach(elements;; object mat)
	{
		// assume that any activator greater than 1 character is a ligature we would like to automatically use.
		// we allow this to be short circuited by making the activator start with an @ sign (such as @ct for a 
		// non-automatically applied ligature "ct".)
		if(mat->activator && sizeof(mat->activator) > 1 && mat->activator[0] != '@')  
		  ligatures += ({mat});
	}
	
	return ligatures;
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

