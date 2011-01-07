import Fins;

inherit DocController;

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
}


public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_wedges();
  view->add("wedges", m);
}

public void new(Request id, Response response, Template.View view, mixed args)
{
	
	if(id->variables->name)
	{
		if(app->wedge_exists(id->variables->name, id->misc->session_variables->user))	
		{
			response->flash("Wedge " + upper_case(id->variables->name) + " already exists.");
			return;
		}
		
		Monotype.Stopbar l = Monotype.Stopbar();
		l->set_name(upper_case(id->variables->name));
		
		app->save_wedge(l, id->misc->session_variables->user, id->variables->is_public);
		
		response->redirect(edit, ({id->variables->name}));
	}
}

public void cancel(Request id, Response response, Template.View view, mixed args)
{
	id->misc->session_variables->wedge = 0;
	
	response->flash("Your changes were cancelled.");
	response->redirect(index);
}

public void save(Request id, Response response, Template.View view, mixed args)
{
	foreach(glob("row*", indices(id->variables));;string q)
	{
		int r;
		
		[r] = array_sscanf(q, "row%d");
		
		id->misc->session_variables->wedge->set(r, (int) id->variables[q]);
	}
	
	app->save_wedge(id->misc->session_variables->wedge, id->misc->session_variables->user, id->variables->is_public);
	id->misc->session_variables->wedge = 0;
	
	response->flash("Your changes were saved.");
	response->redirect(index);	
}

public void do_delete(Request id, Response response, Template.View view, mixed args)
{
  object wedge;

  if(!sizeof(args))
  {
	response->set_data("You must provide a wedge to delete.");
  }

  wedge = app->load_wedge(args[0], id->misc->session_variables->user);

  if(!wedge)
  {
    response->flash("Wedge " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("Wedge " + args[0] + " successfully deleted.");
    app->delete_wedge(args[0], id->misc->session_variables->user);
    response->redirect(index);
  }
}

public void delete(Request id, Response response, Template.View view, mixed args)
{
  object wedge;

  if(!sizeof(args))
  {
	response->set_data("You must provide a wedge to delete.");
  }
  wedge = app->load_wedge(args[0], id->misc->session_variables->user);
  if(!wedge)
  {
    response->flash("Wedge " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->redirect(do_delete, args);
  }
}


public void edit(Request id, Response response, Template.View view, mixed args)
{
  object wedge;

  if(!sizeof(args))
  {
	response->set_data("You must provide a wedge to edit.");
  }

werror("args:%O, %O\n", getcwd(),combine_path(app->config["locations"]["wedges"], args[0]));
  wedge = app->load_wedge(args[0], id->misc->session_variables->user);
  id->misc->session_variables->wedge = wedge;
  view->add("wedge", wedge);
}

public void download(Request id, Response response, Template.View view, mixed args)
{
	object wedge;
	
	  if(!sizeof(args))
	  {
		response->set_data("You must provide a wedge to download.");
	  }

	  wedge = app->load_wedge(args[0], id->misc->session_variables->user);
	
	response->set_data(Public.Parser.XML2.render_xml(wedge->dump()));
    response->set_header("content-disposition", "attachment; filename=" + 
        args[0] + ".xml");	
    response->set_type("application/x-monotype-e-stopbar");
    response->set_charset("utf-8");
   
}