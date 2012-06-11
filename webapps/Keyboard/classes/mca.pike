import Fins;

inherit "mono_doccontroller";

void start()
{
  before_filter(app->admin_user_filter);
}

int __quiet = 1;

   array cols15 = ({ /* 15 elements */
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
                "L", "M", "N", "O"
            });

   array cols17 = ({ /* 17 elements */
                "NI", "NL", "A", "B", "C", "D", "E", "F", "G", "H", "I", 
                "J", "K", "L", "M", "N", "O"
            });

  array rows15 = ({ /* 15 elements */
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
            });

  array rows16 = ({ /* 16 elements */
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
            });

array small_caps_elements = 
  ({
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", 
      "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
      "Y", "Z"
  });

array full_alphabet_elements = 
  ({
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", 
      "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
      "Y", "Z",
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
      "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
      "y", "z",
      "ff", "fi", "fl", "ffi", "ffl", "oe", "ae",
      "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
      ".", ",", ":", ";", "!", "?", "&", "-", "$"
  });

mapping case_contents = ([
							"R": full_alphabet_elements,
			  				"S": small_caps_elements,
							"B": full_alphabet_elements,
                          	"I": full_alphabet_elements
						]);


public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_mcas();
  object owner = id->misc->session_variables->user;
  m = filter(m, lambda(object mca){ if(mca["owner"] ==  owner || mca["is_public"]) return true; else return false; });

  view->add("owner", owner);
  view->add("mcas", m);
}


public void do_delete(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide a matcase to delete.");
  }

  mca = app->load_matcase_by_id(args[0], id->misc->session_variables->user);

  if(!mca)
  {
    response->flash("MCA ID " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("MCA " + args[0] + " successfully deleted.");
    app->delete_matcase(args[0], id->misc->session_variables->user);
    response->redirect(index);
  }
}

public void unshare(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
    response->set_data("You must provide an MCA to share.");
    response->redirect(index);
    return;    
  }
  
werror("unshare()\n");
  mca = app->load_matcase_dbobj_by_id(args[0], id->misc->session_variables->user);
werror("unshare(%O)\n", mca);

  if(!mca)
  {
    response->flash("MCA ID " + args[0] + " was not found or not owned by you.");
    response->redirect(index);
  }
  else
  {
	mca["is_public"] = 0;
	response->flash("MCA " + mca["name"] + " is now unshared.");
    response->redirect(index);
  }
}



public void share(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
    response->set_data("You must provide an MCA to share.");
    response->redirect(index);
    return;    
  }
  
werror("share()\n");
  mca = app->load_matcase_dbobj_by_id(args[0], id->misc->session_variables->user);
werror("share(%O)\n", mca);

  if(!mca)
  {
    response->flash("MCA ID " + args[0] + " was not found or not owned by you.");
    response->redirect(index);
  }
  else
  {
	mca["is_public"] = 1;
	response->flash("MCA " + mca["name"] + " is now shared.");
    response->redirect(index);
  }
}


public void delete(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
    response->set_data("You must provide an MCA to delete.");
    response->redirect(index);
    return;    
  }
  
werror("delete()\n");
  mca = app->load_matcase_by_id(args[0], id->misc->session_variables->user);
werror("delete(%O)\n", mca);

  if(!mca)
  {
    response->flash("MCA ID " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->redirect(do_delete, args);
  }
}

public void copy(Request id, Response response, Template.View view, mixed args)
{
  Monotype.MatCaseLayout mca;
  mca = app->load_matcase_by_id(args[0], /*id->misc->session_variables->user*/);

  view->add("mca", mca);
  view->add("wedges", app->get_wedges());

  if(!id->variables->name || !sizeof(id->variables->name))
  {
    response->flash("You must supply a name for the copy.");
    return;	
  }

  if(id->variables->size)
  {
	if(app->mca_exists(id->variables->name, id->misc->session_variables->user))
	{
		response->flash("MCA " + id->variables->name + " already exists.");
		return;
	}
	else 
	  mca->set_name(id->variables->name);

	mca->set_description(id->variables->description);
	mca->set_wedge(id->variables->wedge);
	mca->set_size((int)id->variables->size);
    object mca_db = app->save_matcase(mca, id->misc->session_variables->user, id->variables->is_public);		
    response->redirect(edit, ({(string)mca_db["id"]}));
  }
}

public void new(Request id, Response response, Template.View view, mixed args)
{
  view->add("wedges", app->get_wedges());
  Monotype.MatCaseLayout l;
  if(id->variables->size)
  {
    id->variables->name = String.trim_whites(id->variables->name);

    if(app->mca_exists(id->variables->name, id->misc->session_variables->user))
    {
      response->flash("MCA " + id->variables->name + " already exists.");
      return;
    }
		
    l = Monotype.MatCaseLayout((int)id->variables->size);
    l->set_description(id->variables->description);
    l->set_name(id->variables->name);
    l->set_wedge(id->variables->wedge);
		
    object mca_db = app->save_matcase(l, id->misc->session_variables->user, id->variables->is_public);
		
    response->redirect(edit, ({(string)mca_db["id"]}));
  }
}

public void cancel(Request id, Response response, Template.View view, mixed args)
{
  id->misc->session_variables->mca = 0;
	
  response->flash("Your changes were cancelled.");
  response->redirect(index);
}

public void save(Request id, Response response, Template.View view, mixed args)
{
	werror("save\n");
if(catch(
	app->save_matcase(id->misc->session_variables->mca, id->misc->session_variables->user, id->variables->is_public)))
response->set_data(sprintf("<pre>Request Debug: %O\n\n%O</pre>\n", id->cookies, id->misc));
	id->misc->session_variables->mca = 0;

	response->flash("Your changes were saved.");
	response->redirect(index);
}

public void setMat(Request id, Response response, Template.View view, mixed args)
{
	werror(string_to_utf8("setting mat for " + id->variables->col + " " + id->variables->row + " with " + id->variables->matrix));
 object mca = id->misc->session_variables->mca;
werror("%O", mkmapping(indices(id), values(id)) );
  if(id->variables->matrix == "")
  {
    mca->delete(id->variables->col, (int)id->variables->row);
  }
  else
  {

// we might get the mat from the client as xml, or we might not. 
// we try both approaches and hope the one we select is okay.

    string matxml = id->variables->xmatrix;
    string m2;

    mixed e = catch
    {

      m2 = utf8_to_string(matxml);
    };

    if(e || !m2)
        matxml = string_to_utf8(matxml);

    object n = Public.Parser.XML2.parse_xml(matxml);
    object m = Monotype.Matrix(n);
    werror("n: %O", n);
    mca->set(id->variables->col, (int)id->variables->row, m);
  }

werror("!!!\n!!!\n");
  response->set_data("");
}

public void getMat(Request id, Response response, Template.View view, mixed args)
{
  // the column is a string (a - o)
  // the row is an int 1 - 15
  string resp;
  string col = id->variables->col;
  int row = (int)id->variables->row;
  object mat;

//  werror("%O\n\n", id->misc->session_variables->mca->matcase[col]);

  mapping column = id->misc->session_variables->mca->matcase[col];
  if(column)
   mat = column[row];
  if(mat) resp = mat->dump();
  else resp = "";
  // we try to encode the string as utf8.
  response->set_data(string_to_utf8((string)resp));
  response->set_type("text/xml");
}

public void replaceMat(Request id, Response response, Template.View view, mixed args)
{
  string col;
  int row;

  [row, col] = array_sscanf(id->variables->pos, "%d%[A-O]s");

  werror("mca: %O\n", id->variables->matrix);
  mapping mat = Tools.JSON.deserialize(id->variables->matrix)->data;
  werror("%s %d: %O\n", col, row, mat); 
  object matrix = Monotype.Matrix(); 

  object mca = id->misc->session_variables->mca;
  object wedge = app->load_wedge(mca->wedge);
  int sw = wedge->get(row);

  matrix->set_character(mat->character);
  matrix->set_activator(mat->character);
  matrix->set_style(mat->style);
  matrix->set_set_width(sw);

  mca->set(col, row, matrix);
  response->set_data("");
}

// move a mat around in the MCA
public void moveMat(Request id, Response response, Template.View view, mixed args)
{
  string col;
  int row;

  [row, col] = array_sscanf(id->variables->from, "%d%[A-O]s");

  object mca = id->misc->session_variables->mca;
  object wedge = app->load_wedge(mca->wedge);

  object matrix = mca->get(col, row);
  mca->delete(col, row);

  [row, col] = array_sscanf(id->variables->to, "%d%[A-O]s");

  wedge = app->load_wedge(mca->wedge);
  int sw = wedge->get(row);
  
  matrix->set_set_width(sw);

  mca->set(col, row, matrix);
  response->set_data("OK");
}


public void edit(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide a mat case layout to edit.");
  }

  view->add("now", (string)time());

  mca = app->load_matcase(args[0]);
  werror("**** name: %O mca: %O wedge: %O\n", args[0], mca, mca?mca->wedge:0);

  if(mca->wedge)
  {
    object wedge = app->load_wedge(mca->wedge);
    if(!wedge) // if a user doesn't have their own wedge, try loading a global one.
/*
    {
      int wedgeid;
      array x = Fins.Model.find.stopbars(([ "name": mca->wedge ]));
      if(sizeof(x))
      {
         wedgeid = x[0]["id"];
         wedge = app->w(wedgeid);
      }
      else
*/
      {
        throw(Error.Generic("Unable to load wedge " + mca->wedge + " for user.")); 
      }
   // }
    view->add("wedge", wedge);
  }

  id->misc->session_variables->mca = mca;

object dbo = app->load_matcase_dbobj_by_id(args[0]);
if(dbo && dbo["owner"] == id->misc->session_variables->user)
  view->add("is_owner", 1);
else
  view->add("is_owner", 0);

  array r,c;
  switch(mca->matcase_size)
  {
    case Monotype.MATCASE_15_15:
      r = rows15;
      c = cols15;
      break;
    case Monotype.MATCASE_15_17:
      r = rows15;
      c = cols17;
      break;
    case Monotype.MATCASE_16_17:
      r = rows16;
      c = cols17;
      break;
  }

  view->add("mca", mca);
  view->add("rows", r);   
  view->add("cols", c);
  view->add("problems", mca->problems);
  view->add("description", mca->description);
  
  // generate "elements not in matcase" data
  mapping not_in_matcase = copy_value(case_contents);
 
  foreach(mca->elements; string act; object matrix)
  {
    string style = matrix->style;
    if(!style || style == "") style = "R";
    array z;
if(matrix->character == "0")
   werror("%O\n", (mapping)matrix);
    if((z = not_in_matcase[style]) && search(z, matrix->character)!= -1)
    {
      not_in_matcase[style] -= ({ matrix->character });
      if(matrix->character == "0") werror("removing " + matrix->character + "\n"); 
    }
    
  }  
  view->add("not_in_matcase", not_in_matcase);    

  // response->set_data("<pre>" + sprintf("%O", not_in_matcase));

}

public void saveDescription(Request id, Response response, Template.View view, mixed args)
{
    werror("variables: %O\n", id->variables);
    object mca = id->misc->session_variables->mca;
    mca->set_description(id->variables->description);
    response->set_data("Description Set: " + mca->get_description);
    
}

public void notInCase(Request id, Response response, Template.View view, mixed args)
{
    object mca = id->misc->session_variables->mca;
    mapping not_in_matcase = copy_value(case_contents);

    foreach(mca->elements; string act; object matrix)
    {
      string style = matrix->style;
      if(!style || style == "") style = "R";
      array z;
  if(matrix->character == "0")
     werror("%O\n", (mapping)matrix);
      if((z = not_in_matcase[style]) && search(z, matrix->character)!= -1)
      {
        not_in_matcase[style] -= ({ matrix->character });
        if(matrix->character == "0") werror("removing " + matrix->character + "\n"); 
      }

    }  
    
    response->set_data(Tools.JSON.serialize(not_in_matcase));  
    response->set_type("application/json");
}

public void download(Request id, Response response, Template.View view, mixed args)
{
	object mca;
	
	  if(!sizeof(args))
	  {
		response->set_data("You must provide an MCA to download.");
	  }

	  mca = app->load_matcase_dbobj_by_id(args[0], id->misc->session_variables->user);
	
	response->set_data(mca["xml"]);
    response->set_header("content-disposition", "attachment; filename=" + 
        mca["name"] + ".xml");	
    response->set_type("application/x-monotype-e-matcase");
    response->set_charset("utf-8");
   
}

public void upload(Request id, Response response, Template.View view, mixed args)
{
   object mca;

   mixed e = catch(mca = Monotype.load_matcase_string(id->variables->file));
   if(e)
	{
		response->flash("Unable to read the Matcase. Are you sure you uploaded an MCA definition file?");
		response->redirect(index);
		return;
	}
	
	if(mca->name)
	{
		object nw;
		
		object e = catch(nw = app->load_matcase(mca->name, id->misc->session_variables->user));

		if(nw)
		{
			response->flash("You already have an MCA named " + mca->name +". Please delete the existing definition and retry.");
			response->redirect(index);
			return;			
		}
	}
	else
	{
		response->flash("No matcase name specified. Are you sure you uploaded an MCA definition file?");
		response->redirect(index);
		return;		
	}

	app->save_matcase(mca, id->misc->session_variables->user, id->variables->is_public);
	
	response->flash("Matcase Arrangement " + mca->name + " was successfully imported.");
	response->redirect(index);
	return;	
}
