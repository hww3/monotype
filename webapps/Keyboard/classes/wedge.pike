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
		string file_name = combine_path(getcwd(), app->config["locations"]["wedges"], upper_case(id->variables->name) + ".xml");
		if(file_stat(file_name))
		{
			response->flash("Wedge " + upper_case(id->variables->name) + " already exists.");
			return;
		}
		
		Monotype.Stopbar l = Monotype.Stopbar();
		l->set_name(upper_case(id->variables->name));
		
		app->save_wedge(l);
		
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
	
	app->save_wedge(id->misc->session_variables->wedge);
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

  wedge = app->load_wedge(args[0]);

  if(!wedge)
  {
    response->flash("Wedge " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("Wedge " + args[0] + " successfully deleted.");
    app->delete_wedge(args[0]);
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
  wedge = app->load_wedge(args[0]);
  if(!wedge)
  {
    response->flash("Wedge " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->redirect(do_delete, args[0]);
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
  wedge = app->load_wedge(args[0]);
  id->misc->session_variables->wedge = wedge;
  view->add("wedge", wedge);
}

