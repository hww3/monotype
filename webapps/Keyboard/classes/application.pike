
inherit Fins.Application;

void save_matcase(Monotype.MatCaseLayout mca)
{
	string file_name;
	object node = mca->dump();
	file_name = combine_path(getcwd(), config["locations"]["matcases"], mca->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));
}

void save_wedge(Monotype.Stopbar wedge)
{
	string file_name;
	object node = wedge->dump();
	file_name = combine_path(getcwd(), config["locations"]["wedges"], wedge->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));
}


object load_wedge(string wedgename)
{
	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

int delete_wedge(string wedgename)
{

	werror("deleting " + combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml") + "\n");

	return rm(combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml"));	
}


int delete_matcase(string matcase)
{
    werror("deleting " + combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml") + "\n");
	return rm(combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml"));	
}

object load_matcase(string matcasename)
{
	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

array get_mcas()
{
	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array get_wedges()
{
	return map(glob("*.xml", get_dir(config["locations"]["wedges"]) || ({})), lambda(string s){return (s/".xml")[0];});
}


int admin_user_filter(Fins.Request id, Fins.Response response, mixed ... args)
{
   if(!id->misc->session_variables->user)
   {
      response->flash("msg", "You must login to perform this action.");
      response->redirect(controller->auth->login, 0, ([ "return_to": id->not_query ]));
      return 0;
   }

   return 1;
}

