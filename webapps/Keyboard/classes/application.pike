
inherit Fins.Application;

void save_matcase(Monotype.MatCaseLayout mca)
{
	string file_name;
	object node = mca->dump();
	
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements_by_alt")(mca->name));
	
	// note: need to handle owner and is_public fields properly.
	if(!mca_db)
	{
	  mca_db = Keyboard.Objects.Matcasearrangement();
	  mca_db["name"] = mca->name;
	  mca_db["is_public"] = 0;
	  mca_db["owner"] = 1;
	  mca_db["xml"] = Public.Parser.XML2.render_xml(node);
	  mca_db->save();
	}
	else mca_db["xml"] = Public.Parser.XML2.render_xml(node);

/*
    file_name = combine_path(getcwd(), config["locations"]["matcases"], mca->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));	
*/
}

void save_wedge(Monotype.Stopbar wedge)
{
	string file_name;
	object node = wedge->dump();
/*
	file_name = combine_path(getcwd(), config["locations"]["wedges"], wedge->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));
*/
	object wedge_db;
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars_by_alt")(wedge->name));
	
	// note: need to handle owner and is_public fields properly.
	if(!wedge_db)
	{
	  wedge_db = Keyboard.Objects.Stopbar();
	  wedge_db["name"] = wedge->name;
	  wedge_db["is_public"] = 0;
	  wedge_db["owner"] = 1;
	  wedge_db["xml"] = Public.Parser.XML2.render_xml(node);
	  wedge_db->save();
	}
	else wedge_db["xml"] = Public.Parser.XML2.render_xml(node);

}


object load_wedge(string wedgename)
{
	object wedge_db;
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars_by_alt")(wedgename));
	if(wedge_db)
  	  return Monotype.load_stopbar_string(wedge_db["xml"]);
	else return 0;
//	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

object old_load_wedge(string wedgename)
{
	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

int delete_wedge(string wedgename)
{
	object wedge_db;
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars_by_alt")(wedgename));
	if(wedge_db)
		return wedge_db->delete();
	else return 0;
//	werror("deleting " + combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml"));	
}


int delete_matcase(string matcase)
{
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements_by_alt")(matcase));
	if(mca_db)
		return mca_db->delete();
	else return 0;
    werror("deleting " + combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml"));	
}

object load_matcase(string matcasename)
{
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements_by_alt")(matcasename));
	if(mca_db)
  	  return Monotype.load_matcase_string(mca_db["xml"]);
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object old_load_matcase(string matcasename)
{
	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

array get_mcas()
{
	return master()->resolv("Fins.Model.find.matcasearrangements_all")()["name"];
//	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array get_wedges()
{
	return master()->resolv("Fins.Model.find.stopbars_all")()["name"];
//	return map(glob("*.xml", get_dir(config["locations"]["wedges"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array old_get_mcas()
{
	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array old_get_wedges()
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

int admin_only_user_filter(Fins.Request id, Fins.Response response, mixed ... args)
{
   if(!id->misc->session_variables->user || !id->misc->session_variables->user["is_admin"])
   {
      response->flash("msg", "You must be an admin user to perform this action.");
      response->redirect(controller->auth->login, 0, ([ "return_to": id->not_query ]));
      return 0;
   }

   return 1;
}
