import Fins;

inherit DocController;

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

mapping case_contents = (["R": full_alphabet_elements,
			  "S": small_caps_elements,
                          "I": full_alphabet_elements]);


public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = app->get_mcas();
  view->add("mcas", m);
}


public void do_delete(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide a matcase to delete.");
  }

  mca = app->load_matcase(args[0]);

  if(!mca)
  {
    response->flash("MCA " + args[0] + " was not found.");
    response->redirect(index);
  }
  else
  {
    response->flash("MCA " + args[0] + " successfully deleted.");
    app->delete_matcase(args[0]);
    response->redirect(index);
  }
}

public void delete(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide an MCA to delete.");
  }

  mca = app->load_matcase(args[0]);

  if(!mca)
  {
    response->flash("MCA " + args[0] + " was not found.");
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

// we might get the mat from the client as xml, or we might not. 
// we try both approaches and hope the one we select is okay.

    string matxml = id->variables->matrix;
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
}

public void replaceMat(Request id, Response response, Template.View view, mixed args)
{
  string col;
  int row;

  [row, col] = array_sscanf(id->variables->pos, "%d%[A-O]s");

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
  view->add("problems", mca->problems);
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


