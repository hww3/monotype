import Fins;
import Tools.Logging;

inherit "mono_doccontroller";

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
}

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


// don't need authentication to access the MCA display.
constant _no_auth_display = 1;

public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_mcas();
  object owner = id->misc->session_variables->user;
  m = filter(m, lambda(object mca){ if(mca["owner"] ==  owner || mca["is_public"]) return true; else return false; });

  view->add("owner", owner);
  view->add("mcas", m);
}


public void do_delete(Request id, Response response, Template.View view, mixed ... args)
{
  object mca;
  string mca_id = id->variables->mca_id;

  if(!sizeof(args))
  {
	response->set_data("You must provide a matcase to delete.");
  }

  mca = app->load_matcase_by_id(mca_id, id->misc->session_variables->user);

  if(!mca)
  {
    response->flash("MCA ID " + mca_id + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("MCA " + mca["name"] + " successfully deleted.");
    app->delete_matcase(mca_id, id->misc->session_variables->user);
    response->redirect(index);
  }
}

public void unshare(Request id, Response response, Template.View view, mixed ... args)
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



public void share(Request id, Response response, Template.View view, mixed ... args)
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


// TODO: this really should prompt for confirmation, rather than just doing the deed.
public void delete(Request id, Response response, Template.View view, mixed ... args)
{
  object mca;

  if(!sizeof(args))
  {
    response->set_data("You must provide an MCA to delete.");
    response->redirect(index);
    return;    
  }
  
  mca = app->load_matcase_by_id(args[0], id->misc->session_variables->user);

  if(!mca)
  {
    response->flash("MCA ID " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    view->add("mca", mca);
    view->add("mca_id", args[0]);
//    response->redirect(do_delete, args);
  }
}

public void copy(Request id, Response response, Template.View view, mixed ... args)
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

public void rename(Request id, Response response, Template.View view, mixed ... args)
{
  Monotype.MatCaseLayout mca;
  mca = app->load_matcase_by_id(args[0], /*id->misc->session_variables->user*/);

  view->add("mca", mca);

  if(!id->variables->name || !sizeof(id->variables->name))
  {
    return;	
  }
  else
  {
    if(app->mca_exists(id->variables->name, id->misc->session_variables->user))
    {
      response->flash("MCA " + id->variables->name + " already exists.");
      return;
    }
    else 
    {
      object mca_db = app->rename_matcase(mca, id->variables->name, id->misc->session_variables->user, id->variables->is_public);		
      response->flash("msg", "MCA renamed to \"" + id->variables->name + "\" successfully.");
      response->redirect(index);
    }
  }
}

public void new(Request id, Response response, Template.View view, mixed args)
{
  view->add("wedges", app->get_wedges());
  Monotype.MatCaseLayout l;
  if(id->variables->size)
  {
    id->variables->name = String.trim_whites(id->variables->name);

    if(!sizeof(id->variables->name))
    {
      response->flash("No MCA name specified.");
      return;
    }

    if(!sizeof(id->variables->wedge))
    {
      response->flash("No stopbar specified.");
      return;
    }

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
object mca_db;
	werror("save\n");
if(catch(mca_db =
	app->save_matcase(id->misc->session_variables->mca, id->misc->session_variables->user, id->variables->is_public)))
response->set_data(sprintf("<pre>Request Debug: %O\n\n%O</pre>\n", id->cookies, id->misc));
werror("mca: %O\n", mca_db["id"]);
  if(id->variables->reopen)
    response->redirect(edit, ({mca_db["id"]}));
  else
    response->redirect(index);
  id->misc->session_variables->mca = 0;
  response->flash("Your changes were saved.");
}

public void setMat(Request id, Response response, Template.View view, mixed args)
{
  mixed e = catch {
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
  
};

if(e)
{
  response->set_data(e[0]);
  log->exception("error occurred while setting a matrix.", e);
}
else
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
  matrix->set_set_width((float)sw);

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
  
  matrix->set_set_width((float)sw);

  mca->set(col, row, matrix);
  response->set_data("OK");
}

public void edit(Request id, Response response, Template.View view, mixed ... args)
{
  if(!sizeof(args))
  {
    response->set_data("You must provide a mat case layout to edit.");
  }
  mixed mcaid = args[0];

  processMCARequest(id, response, view, mcaid);
}

public void pdfdisplay(Request id, Response response, Template.View view, mixed ... args)
{
  object t = this->view->get_view("mca/display");
  object resp = Fins.Response(id);
  display(id, resp, t, @args);
  string fn = sprintf("/tmp/%d_%d_%s", getpid(), time(), args[0]);
  Stdio.write_file(fn + ".html", string_to_utf8(t->render()));
  string command = combine_path(app->config->app_dir, "bin/phantomjs") + " " + combine_path(app->config->app_dir, "bin/render.js") + " " + fn + ".html " +fn + ".pdf Letter 0.80";
  Log.info(command);
  string result = Process.popen(command);
  Log.info("result: %O", result);
  response->set_data(Stdio.read_file(fn + ".pdf"));
  response->set_type("application/pdf");
  
 //  object mca = app->load_matcase(args[0]);
 // response->set_header("content-disposition", "attachment; filename=\"" + 
 //      mca["name"] + ".pdf\"");
  rm(fn + ".pdf");
  rm(fn + ".html");
}

public void display(Request id, Response response, Template.View view, mixed ... args)
{
  if(!sizeof(args))
  {
    response->set_data("You must provide a mat case layout to display.");
    return;
  }
  mixed mcaid = args[0];

  view->set_layout("mca/display_layout");
  processMCARequest(id, response, view, mcaid);
}

int processMCARequest(Request id, Response response, Template.View view, string mcaid)
{
  object mca;
  object dbo = app->load_matcase_dbobj_by_id(mcaid);

  view->add("now", (string)time());

  mca = app->load_matcase(mcaid);
  werror("view: %O %O\n", view, mca);
  
  if(dbo && dbo["owner"] != id->misc->session_variables->user && !dbo["is_public"])
  {
		throw(Error.Generic("Unable to view this MCA."));
		return 0;
  }

  werror("**** name: %O mca: %O wedge: %O\n", mcaid, mca, mca?mca->wedge:0);

  if(mca->wedge)
  {
    object wedge = app->load_wedge(mca->wedge);
    if(!wedge) // if a user doesn't have their own wedge, try loading a global one.
    {
      throw(Error.Generic("Unable to load wedge " + mca->wedge + " for user.")); 
    }
    view->add("wedge", wedge);
  }

  id->misc->session_variables->mca = mca;

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
  view->add("dbo", dbo);
  view->add("problems", mca->problems);
  view->add("description", mca->description);

  // generate "elements not in matcase" data
  mapping not_in_matcase = get_case_contents(id);
 
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
  return 1;
}


mapping get_case_contents(object id)
{
  if(!id->misc->session_variables->user) return ([]);
  
  array full_alphabet_elements = ((replace(id->misc->session_variables->user["Preferences"]["full_sorts_palette_contents"]["value"], ({"\t", "\r", "\n"}), ({" ", " ", " "})) / " ") - ({""}));
  array small_caps_elements = ((replace(id->misc->session_variables->user["Preferences"]["sc_sorts_palette_contents"]["value"], ({"\t", "\r", "\n"}), ({" ", " ", " "})) / " ") - ({""}));
  
  mapping case_contents = ([
  							"R": full_alphabet_elements,
  			  				"S": small_caps_elements,
  							"B": full_alphabet_elements,
                            	"I": full_alphabet_elements
  						]);
  return case_contents;
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
    mapping not_in_matcase = get_case_contents(id);

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

public void download(Request id, Response response, Template.View view, mixed ... args)
{
	object mca;
	
	  if(!sizeof(args))
	  {
		response->set_data("You must provide an MCA to download.");
	  }
	  
	  mca = app->load_matcase_dbobj_by_id(args[0]);

    if(mca && mca["owner"] != id->misc->session_variables->user && !mca["is_public"])
    {
  		response->set_data("Unable to view this MCA.");
  		return;
	  }
	response->set_data(mca["xml"]);
    response->set_header("content-disposition", "attachment; filename=\"" + 
        mca["name"] + ".xml\"");	
    response->set_type("application/x-monotype-e-matcase");
    response->set_charset("utf-8");
   
}


public void downloadzip(Request id, Response response, Template.View view, mixed ... args)
{
	object mca;
  string name, data;
  
   array mcas = id->misc->session_variables->user["mcas"];
   Tools.Zip z = Tools.Zip();

   foreach((array)mcas;; mca)
   {
     data = mca["xml"];
     name = mca["name"];
     z->add_file("all_mcas" + "/" + name + ".xml", data);     
   }
   

     response->set_data(z->generate());
     response->set_type("application/zip");
     response->set_header("Content-Disposition", sprintf("attachment; filename=\"%s\"", "all_mcas.zip"));
}



public void uploadzip(Request id, Response response, Template.View view, mixed args)
{
   object msgs = ADT.List();
   
     object z;
     if(catch(z = Filesystem.Zip("mcas.zip", 0, Stdio.FakeFile(id->variables->file))))
     {
        response->flash("Invalid MCA or Zip file."); 
      	response->redirect(index);
     }
     
     low_unzip(z, msgs, id->misc->session_variables->user);
    
  response->flash((array)msgs * "<br/>");
	response->redirect(index);
	return;	
}


void low_unzip(object z, object msgs, object user)
{
  string cwd = z->cwd();
  
  foreach(z->get_dir();; string fn)
  {
    string s;
    object mca;
    werror("cwd: %O filename: %O\n", cwd, fn);
    if(z->stat(fn)->isdir)
    {
      low_unzip(z->cd(fn), msgs, user);
    }
    else
    {
      string file = z->open(fn)->read();      
werror("got some data: %O\n", file);
       mixed e = catch(mca = Monotype.load_matcase_string(file));
       if(e)
    	 {
    		 msgs->append("Unable to read the Matcase '" + fn + "'. Are you sure you uploaded an MCA definition file?");
    		 continue;
    	  }

    	  if(mca->name)
    	  {
    		 object nw;

    		  object e = catch(nw = app->load_matcase(mca->name, user));

    	  	if(nw)
      		{
    			  msgs->append("You already have an MCA named " + mca->name +". Please delete the existing definition and retry.");
    			  continue;
    		  }
    	  }
    	  else
      	{
    		  msgs->append("No matcase name specified. Are you sure you uploaded an MCA definition file?");
          continue;
      	}

    	  app->save_matcase(mca, user, 0);
      	msgs->append("Matcase Arrangement " + mca->name + " was successfully imported.");
    }
  }
}

public void upload(Request id, Response response, Template.View view, mixed... args)
{
   object mca;

   mixed e = catch(mca = Monotype.load_matcase_string(id->variables->file));
   if(e)
	{
	  uploadzip(id, response, view, @args);
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
