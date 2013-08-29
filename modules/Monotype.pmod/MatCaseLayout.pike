import Public.Parser.XML2;
import Monotype;
array problems = ({});
string name;
string description;
int matcase_size;
string wedge;
mapping spaces = ([]);
object justifying_space;

object punct_regex;

int maxrow = 15;
multiset validcolumns = (<"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", 
        "L", "M", "N", "O">);
// mapping of columns containing a mapping for each row.
mapping matcase = ([]);
mapping elements = ([]);

string encode(object o)
{
  Node n = dump();
  string xml = n->render_xml(0,0);
  return encode_value(xml);
}

object decode(string v)
{
  object m = this_program()();
  object n = Public.Parser.XML2.parse_xml(decode_value(v), "mca_internal.xml");
  m->load(n);
  return m;
}

void create(int|void size)
{
  matcase_size = size;

  switch(size)
  {
	case Monotype.MATCASE_15_15:
	  break;
	case Monotype.MATCASE_15_17:
	  validcolumns = (<"NI", "NL" >) + validcolumns;
	  break;
	case Monotype.MATCASE_16_17:
      validcolumns = (<"NI", "NL" >) + validcolumns;
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
    elements["SPACE_"+ (int)mat->set_width] = mat;
    if(spaces[(int)mat->set_width])
      add_problem(column, row, sprintf("Redundant space in row %d.", row));
    spaces[(int)mat->set_width] = mat;
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
       string key2 = mat->activator;
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

       add_problem(column, row, sprintf("Matcase contains duplicate mat: %s:new %s %d, orig %s %d\n", 
	    key2, column, row, elements[key]->col_pos, elements[key]->row_pos));
    }
    elements[key] = mat;
  if(mat->style =="R" && mat->character == "0")
  { 
    werror(string_to_utf8(sprintf("loaded %s: %O\n", key, (mapping)mat)));
  }

  }
}

private void add_problem(string column, int row, string desc)
{
       problems += ({ ({column, row, string_to_utf8(desc)}) });
       werror(string_to_utf8(desc));
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


int is_punctuation(string character)
{
  if(!punct_regex) 
    punct_regex = Regexp.PCRE.Widestring("\\pP");
  if(character)
    return punct_regex->match(character);  
  else return 0;
}

array get_highspaces(object wedge)
{
  array highspaces = ({});

  highspaces = get_empties(wedge);
 
  return highspaces;
}

array get_empties(object wedge)
{
  array empties = ({});

  for(int row = 1; row <= maxrow; row++)
  {
    foreach(validcolumns; string column;)
    {
      if(!get(column, row))
      {
        object m = Matrix();
        m->set_position(row, column);
        m->set_character(" ");
        m->set_set_width((float)wedge->get(row));
        m->is_hs = 1;

        empties += ({m});
      }
    }
  }

  return empties;
}

array get_punctuation()
{
  array punctuation = ({});

	foreach(elements;; object mat)
	{
  	if(mat->character && is_punctuation(mat->character))
  	
  		 punctuation += ({mat});
  }

	return punctuation;
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
      string col = c->get_attributes()["column"];
      int row = (int)(c->get_attributes()["row"]);
      object m = select_xpath_nodes("matrix", c)[0];
      set(col, row,  
          Matrix(m, lambda(string x){ add_problem(col, row, x + " (" + col + row + ")");}));
    }
  }

  if(!justifying_space)
    add_problem(0, 0, "Matcase does not contain a Justifying Space.");
  if(!sizeof(spaces))
    add_problem(0, 0, "Matcase contains no fixed spaces.");
  else if(sizeof(spaces) < 4)
    add_problem(0, 0, sprintf("Matcase contains low number (%d) of fixed spaces.", sizeof(spaces)));

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

