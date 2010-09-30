
inherit Fins.Application;

void migrate_old_to_db()
{
	foreach(old_get_wedges();;string q)
	  save_wedge(old_load_wedge(q), master()->resolv("Fins.Model.find.users_by_id")(1));

	foreach(old_get_mcas();;string q)
	  save_matcase(old_load_matcase(q), master()->resolv("Fins.Model.find.users_by_id")(1));
}

void save_matcase(Monotype.MatCaseLayout mca, object user, int|void is_public)
{
	string file_name;
	if(!mca) throw(Error.Generic("No MCA provided.\n"));
	
	object node = mca->dump();
	
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": mca->name, "owner": user]))[0]);
	
	// note: need to handle owner and is_public fields properly.
	if(!mca_db)
	{
		werror("saving new mca " + mca->name + "\n");
	  mca_db = Keyboard.Objects.Matcasearrangement();
	  mca_db["name"] = mca->name;
	  mca_db["is_public"] = 0;
	  mca_db["owner"] = user;
	  mca_db["xml"] = Public.Parser.XML2.render_xml(node);
	  mca_db->save();
	}
	else
	{
		werror("saving existing mca " + mca->name + "\n");
		mca_db->set_atomic((["is_public": is_public, "xml": Public.Parser.XML2.render_xml(node)]));
	}
/*
    file_name = combine_path(getcwd(), config["locations"]["matcases"], mca->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));	
*/
}

void save_wedge(Monotype.Stopbar wedge, object user, int|void is_public)
{
	string file_name;
	object node = wedge->dump();
/*
	file_name = combine_path(getcwd(), config["locations"]["wedges"], wedge->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));
*/
	object wedge_db;
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedge->name, "owner": user]))[0]);
	
	// note: need to handle owner and is_public fields properly.
	if(!wedge_db)
	{
	  wedge_db = Keyboard.Objects.Stopbar();
	  wedge_db["name"] = wedge->name;
	  wedge_db["is_public"] = 0;
	  wedge_db["owner"] = user;
	  wedge_db["xml"] = Public.Parser.XML2.render_xml(node);
	  wedge_db->save();
	}
	else
	{
		 wedge_db->set_atomic((["xml": Public.Parser.XML2.render_xml(node), "is_public": is_public ]));
	}
}


object load_wedge(string wedgename, object user)
{
	object wedge_db;
	if(user)
		catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedgename, "owner": user]))[0]);
	else
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["id": (int)wedgename]))[0]);
	
	if(wedge_db)
  	  return Monotype.load_stopbar_string(wedge_db["xml"]);
	else return 0;
//	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

object old_load_wedge(string wedgename)
{
	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

int delete_wedge(string wedgename, object user)
{
	object wedge_db;
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedgename, "owner": user]))[0]);
	if(wedge_db)
		return wedge_db->delete();
	else return 0;
//	werror("deleting " + combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml"));	
}


int delete_matcase(string matcase, object user)
{
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": matcase, "owner": user]))[0]);
	if(mca_db)
		return mca_db->delete();
	else return 0;
    werror("deleting " + combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml"));	
}

object load_matcase(string matcasename, object user)
{
	object mca_db;
	if(user)
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": matcasename, "owner": user]))[0]);
	else
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)matcasename]))[0]);
	
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
	return master()->resolv("Fins.Model.find.matcasearrangements_all")();
//	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array get_wedges()
{
	return master()->resolv("Fins.Model.find.stopbars_all")();
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

int(0..1) mca_exists(string name, object user)
{
	array r = master()->resolv("Fins.Model.find.matcasearrangements")((["name": name, "owner": user]));
	if(sizeof(r))	
	  return 1;
	else return 0;
}

int(0..1) wedge_exists(string name, object user)
{
	array r = master()->resolv("Fins.Model.find.stopbars")((["name": name, "owner": user]));
	if(sizeof(r))	
	  return 1;
	else return 0;
}

int(0..1) old_mca_exists(string name)
{
	string file_name = combine_path(getcwd(), config["locations"]["matcases"], name + ".xml");
	if(file_stat(file_name))	
	  return 1;
	else return 0;
}

int(0..1) old_wedge_exists(string name)
{
	string file_name = combine_path(getcwd(), config["locations"]["wedges"], name + ".xml");
	if(file_stat(file_name))	
	  return 1;
	else return 0;
}

int admin_user_filter(Fins.Request id, Fins.Response response, mixed ... args)
{
	werror("user: %O\n", id->misc->session_variables->user);
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
