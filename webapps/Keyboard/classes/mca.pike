import Fins;

inherit DocController;

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
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
            });

public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_mcas();
  view->add("mcas", m);
}

public void copy(Request id, Response response, Template.View view, mixed args)
{
  Monotype.MatCaseLayout mca;
  mca = app->load_matcase(args[0]);

  view->add("mca", mca);
  view->add("wedges", app->get_wedges());

  if(!id->variables->name || !sizeof(id->variables->name))
  {
    response->flash("You must supply a name for the copy.");
    return;	
  }

  if(id->variables->size)
  {
	string file_name = combine_path(getcwd(), app->config["locations"]["matcases"], id->variables->name + ".xml");
	if(file_stat(file_name))
	{
		response->flash("MCA " + id->variables->name + " already exists.");
		return;
	}
	else 
	  mca->set_name(id->variables->name);

	mca->set_description(id->variables->description);
	mca->set_wedge(id->variables->wedge);
	mca->set_size((int)id->variables->size);
    app->save_matcase(mca);		
    response->redirect(edit, ({id->variables->name}));
  }
}

public void new(Request id, Response response, Template.View view, mixed args)
{
	view->add("wedges", app->get_wedges());
	Monotype.MatCaseLayout l;
	if(id->variables->size)
	{
		string file_name = combine_path(getcwd(), app->config["locations"]["matcases"], id->variables->name + ".xml");
		if(file_stat(file_name))
		{
			response->flash("MCA " + id->variables->name + " already exists.");
			return;
		}
		
        l = Monotype.MatCaseLayout((int)id->variables->size);
		l->set_description(id->variables->description);
		l->set_name(id->variables->name);
		l->set_wedge(id->variables->wedge);
		
		app->save_matcase(l);
		
		response->redirect(edit, ({id->variables->name}));
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
	app->save_matcase(id->misc->session_variables->mca);
	id->misc->session_variables->mca = 0;
	
	response->flash("Your changes were saved.");
	response->redirect(index);	
}

public void setMat(Request id, Response response, Template.View view, mixed args)
{
	werror("setting mat for " + id->variables->col + " " + id->variables->row + " with " + id->variables->matrix);
    object mca = id->misc->session_variables->mca;
//werror("%O", mkmapping(indices(id), values(id)) );
  if(id->variables->matrix == "")
  {
    mca->delete(id->variables->col, (int)id->variables->row);
  }
  else
  {
    object n = Public.Parser.XML2.parse_xml(id->variables->matrix);
    object m = mca->Matrix(n);
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
//werror("mat: %O\n", (string)resp);
  response->set_data(resp);
}

public void edit(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide a mat case layout to edit.");
  }


werror("args:%O, %O\n", getcwd(),combine_path(app->config["locations"]["matcases"], args[0]));
  mca = app->load_matcase(args[0]);
  if(mca->wedge)
    view->add("wedge", app->load_wedge(mca->wedge));
  id->misc->session_variables->mca = mca;

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
}

