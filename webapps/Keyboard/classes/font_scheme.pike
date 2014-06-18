import Fins;
import Tools.Logging;

inherit "mono_doccontroller";

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
}

// don't need authentication to access the MCA display.
constant _no_auth_display = 1;

public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_font_schemes();
  object owner = id->misc->session_variables->user;
  m = filter(m, lambda(object fs){ if(fs["owner"] ==  owner || fs["is_public"]) return true; else return false; });

  view->add("owner", owner);
  view->add("font_schemes", m);
}


public void do_delete(Request id, Response response, Template.View view, mixed ... args)
{
  object fs;

  if(!sizeof(args))
  {
	response->set_data("You must provide a font scheme to delete.");
  }

  fs = app->load_font_scheme_by_id(args[0], id->misc->session_variables->user);

  if(!fs)
  {
    response->flash("Font Scheme ID " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("Font Scheme " + args[0] + " successfully deleted.");
    app->delete_font_scheme(args[0], id->misc->session_variables->user);
    response->redirect(index);
  }
}

public void unshare(Request id, Response response, Template.View view, mixed ... args)
{
  object fs;

  if(!sizeof(args))
  {
    response->set_data("You must provide an Font Scheme to share.");
    response->redirect(index);
    return;    
  }
  
  werror("unshare()\n");
  fs = app->load_font_scheme_by_id(args[0], id->misc->session_variables->user);
  werror("unshare(%O)\n", fs);

  if(!fs)
  {
    response->flash("Font Scheme ID " + args[0] + " was not found or not owned by you.");
    response->redirect(index);
  }
  else
  {
	  fs["is_public"] = 0;
  	response->flash("Font scheme " + fs["name"] + " is now unshared.");
    response->redirect(index);
  }
}



public void share(Request id, Response response, Template.View view, mixed ... args)
{
  object fs;

  if(!sizeof(args))
  {
    response->set_data("You must provide an Font Scheme to share.");
    response->redirect(index);
    return;    
  }
  
werror("share()\n");
  fs = app->load_font_scheme_by_id(args[0], id->misc->session_variables->user);
werror("share(%O)\n", fs);

  if(!fs)
  {
    response->flash("Font Scheme ID " + args[0] + " was not found or not owned by you.");
    response->redirect(index);
  }
  else
  {
  	fs["is_public"] = 1;
	  response->flash("Font Scheme " + fs["name"] + " is now shared.");
    response->redirect(index);
  }
}


// TODO: this really should prompt for confirmation, rather than just doing the deed.
public void delete(Request id, Response response, Template.View view, mixed ... args)
{
  object fs;

  if(!sizeof(args))
  {
    response->set_data("You must provide an Font Scheme to delete.");
    response->redirect(index);
    return;    
  }
  
werror("delete()\n");
  fs = app->load_font_schemee_by_id(args[0], id->misc->session_variables->user);
werror("delete(%O)\n", fs);

  if(!fs)
  {
    response->flash("Font Scheme ID " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->redirect(do_delete, args);
  }
}

public void copy(Request id, Response response, Template.View view, mixed ... args)
{
  object fs;
  fs = app->load_font_scheme_by_id(args[0], /*id->misc->session_variables->user*/);

  view->add("fs", fs);

  if(!id->variables->name || !sizeof(id->variables->name))
  {
    response->flash("You must supply a name for the copy.");
    return;	
  }
	if(app->font_scheme_exists(id->variables->name, id->misc->session_variables->user))
	{
		response->flash("Font Scheme " + id->variables->name + " already exists.");
		return;
	}
	else 
	{
	  fs = fs->clone();
	  fs["name"] = String.trim_whites(id->variables->name);
    fs["is_public"] = (int) id->variables->is_public;
    fs = app->save_matcase(fs);		
    response->redirect(edit, ({(string)fs["id"]}));
  }
}

public void new(Request id, Response response, Template.View view, mixed args)
{
  if(id->variables->size)
  {
    id->variables->name = String.trim_whites(id->variables->name);

    if(!sizeof(id->variables->name))
    {
      response->flash("No Font Scheme name specified.");
      return;
    }

    if(app->font_scheme_exists(id->variables->name, id->misc->session_variables->user))
    {
      response->flash("Font Scheme " + id->variables->name + " already exists.");
      return;
    }
		
		object l = Keyboard.Objects.Font_scheme();
    l["name"] = id->variables->name;
    l["owner"] = id->misc->session_variables->user;
    l["is_public"] = (int)id->variables->is_public;
    l = app->save_font_scheme(l);
		
    response->redirect(edit, ({(string)l["id"]}));
  }
}

public void cancel(Request id, Response response, Template.View view, mixed args)
{
  id->misc->session_variables->font_scheme = 0;
	
  response->flash("Your changes were cancelled.");
  response->redirect(index);
}

public void save(Request id, Response response, Template.View view, mixed args)
{
object fs;
	werror("save\n");
	mapping json = Tools.JSON.deserialize(id->variables->scheme);
	fs["definition"] = Tools.JSON.serialize(json);
if(catch(fs =
	app->save_font_scheme(id->misc->session_variables->fs)))
response->set_data(sprintf("<pre>Request Debug: %O\n\n%O</pre>\n", id->cookies, id->misc));
werror("fs: %O\n", fs["id"]);
  if(id->variables->reopen)
    response->redirect(edit, ({fs["id"]}));
  else
    response->redirect(index);
  id->misc->session_variables->fs = 0;
  response->flash("Your changes were saved.");
}

public void edit(Request id, Response response, Template.View view, mixed ... args)
{
  if(!sizeof(args))
  {
    response->set_data("You must provide a font scheme to edit.");
  }
  mixed fsid = args[0];

  processFSRequest(id, response, view, fsid);
}


int processFSRequest(Request id, Response response, Template.View view, string fsid)
{
  object fs;
  fs = app->load_font_scheme_by_id(fsid);

  view->add("now", (string)time());

  werror("view: %O %O\n", view, fs);
  
  if(fs && fs["owner"] != id->misc->session_variables->user && !fs["is_public"])
  {
		throw(Error.Generic("Unable to view this Font Scheme."));
		return 0;
  }

  werror("**** name: %O fs: %O\n", fsid, fs);

  id->misc->session_variables->fs = fs;

if(fs && fs["owner"] == id->misc->session_variables->user)
  view->add("is_owner", 1);
else
  view->add("is_owner", 0);

  view->add("fs", fs);

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

public void download(Request id, Response response, Template.View view, mixed ... args)
{
	object fs;
	
	  if(!sizeof(args))
	  {
		response->set_data("You must provide an Font Scheme to download.");
	  }
	  
	  fs = app->load_font_scheme_by_id(args[0]);

    if(fs && fs["owner"] != id->misc->session_variables->user && !fs["is_public"])
    {
  		response->set_data("Unable to view this Font Scheme.");
  		return;
	  }
	response->set_data(fs["definition"]);
    response->set_header("content-disposition", "attachment; filename=\"" + 
        fs["name"] + ".json\"");	
    response->set_type("application/x-monotype-e-font-scheme");
    response->set_charset("utf-8");
   
}

public void upload(Request id, Response response, Template.View view, mixed args)
{
   mapping fs;

   mixed e = catch(fs = Monotype.load_font_scheme_string(id->variables->file));
   if(e)
	{
		response->flash("Unable to read the Font scheme. Are you sure you uploaded a font scheme definition file?");
		response->redirect(index);
		return;
	}
	
	if(fs->name)
	{
		object nw;
		
		object e = catch(nw = app->load_font_scheme(fs->name, id->misc->session_variables->user));

		if(nw)
		{
			response->flash("You already have a font scheme named " + fs["name"] +". Please delete the existing definition and retry.");
			response->redirect(index);
			return;			
		}
	}
	else
	{
		response->flash("No font scheme specified. Are you sure you uploaded an Font scheme definition file?");
		response->redirect(index);
		return;		
	}

  object nfs = Keyboard.Objects.Font_scheme();
  nfs["owner"] = id->misc->session_variables->user;
  nfs["name"] = fs->name;
  nfs["definition"] = Tools.JSON.serialize(fs);
	app->save_font_scheme(nfs);
	
	response->flash("Font Scheme " + fs->name + " was successfully imported.");
	response->redirect(index);
	return;	
}
