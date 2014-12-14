#charset utf8

inherit Fins.Application;

int is_desktop = 0;

void start()
{
::start();
	// among other things, if we're a desktop version of this app, 
	// we always log in autmatically as the user 'desktop'
	if(all_constants()["NSApp"])
	{
werror("RUNNING IN DESKTOP MODE.\n");
	 	is_desktop = 1;
	}

}

void migrate_old_to_db()
{
  migrate_wedges();
  migrate_mcas();
}

void migrate_wedges()
{
	foreach(old_get_wedges();;string q)
	  save_wedge(old_load_wedge(q), master()->resolv("Fins.Model.find.users_by_id")(1));
}

void migrate_mcas()
{
  foreach(old_get_mcas();;string q)
  {
    foreach(master()->resolv("Fins.Model.find.users_all")();;object user)
      save_matcase(old_load_matcase(q), user);
  }
}

object save_matcase(Monotype.MatCaseLayout mca, object user, int|void is_public, object|void updated)
{
	if(!mca) throw(Error.Generic("No MCA provided.\n"));
	
	object node = mca->dump();
	array ret;
	object mca_db;
	mixed e = catch(ret = master()->resolv("Fins.Model.find.matcasearrangements")((["name": mca->name, "owner": user])));
	if(e)
  	werror("error getting mca: %O\n", e);
        if(sizeof(ret)) mca_db = ret[0];
	// note: need to handle owner and is_public fields properly.
	if(!mca_db)
	{
		werror("saving new mca " + mca->name + "\n");
	  mca_db = Keyboard.Objects.Matcasearrangement();
	  mca_db["name"] = mca->name;
	  if(is_public != -1)
  	  mca_db["is_public"] = is_public;
	  mca_db["owner"] = user;
	  mca_db["xml"] = Public.Parser.XML2.render_xml(node);
	  mca_db["updated"] = (updated || Calendar.now())->format_http();  // GMT, hopefully
	  mca_db->save();
	}
	else
	{
		werror("saving existing mca %O " + mca->name + "\n", mca_db);
werror("indices: %O\n", indices(mca_db));
		mca_db->set_atomic((["is_public": (is_public==-1?mca_db["is_public"]:is_public), "xml": Public.Parser.XML2.render_xml(node), "updated": (updated || Calendar.now())->format_http()]));
	}
/*
    file_name = combine_path(getcwd(), config["locations"]["matcases"], mca->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));	
*/
  return mca_db;
}

object rename_matcase(Monotype.MatCaseLayout mca, string new_name, object user, int|void is_public, object|void updated)
{
	if(!mca) throw(Error.Generic("No MCA provided.\n"));
	
	array ret;
	object mca_db;
	mixed e = catch(ret = master()->resolv("Fins.Model.find.matcasearrangements")((["name": mca->name, "owner": user])));
	if(e)
  	werror("error getting mca: %O\n", e);
        if(sizeof(ret)) mca_db = ret[0];
	// note: need to handle owner and is_public fields properly.
	if(!mca_db)
	{
 	  throw(Error.Generic("Unable to fetch MCA " + mca->name + " for user " + user["name"] + ".\n"));
	}
	else
	{
		werror("renaming mca %O " + mca->name + " to " + new_name + "\n", mca_db);
           mca->set_name(new_name);
           object node = mca->dump();
            
		mca_db->set_atomic((["is_public": (is_public==-1?mca_db["is_public"]:is_public), 
			"name": new_name,
			"xml": Public.Parser.XML2.render_xml(node), "updated": (updated || Calendar.now())->format_http()]));
	}
  return mca_db;
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
werror("**** user: %O\n", user);
	object wedge_db;
	array ret;
	catch(ret = master()->resolv("Fins.Model.find.stopbars")((["name": wedge->name, "owner": user])));
        if(sizeof(ret)) wedge_db = ret[0];
	
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

object load_matcase(string matcasename, object|void user)
{
  object mca_db;
  if(user)
    catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": matcasename, "owner": user]))[0]);
  else
    catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)matcasename]))[0]);
	
  if(mca_db)
    return Monotype.load_matcase_string(mca_db["xml"]);
  else return 0;
	
//  return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_matcase_by_id(string id, object user)
{
  object mca_db;
  if(user)
    catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)id, "owner": user]))[0]);
  else
    catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)id]))[0]);
	
  if(mca_db)
    return Monotype.load_matcase_string(mca_db["xml"]);
  else return 0;
	
//  return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_wedge(string wedgename)
{
	object wedge_db;
/*
	if(user)
		catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedgename, "owner": user]))[0]);
	else
*/

	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedgename]))[0]);
	
	if(wedge_db)
  	  return Monotype.load_stopbar_string(wedge_db["xml"]);
	else return 0;
//	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

object old_load_wedge(string wedgename)
{
	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

int delete_wedge(int id, object|void user)
{
  werror("deleting wedge id %O\n", id);
	object wedge_db;
	if(user)
  	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["id": id, "owner": user]))[0]);
  else
  	wedge_db = master()->resolv("Fins.Model.find.stopbars_by_id")(id);
	if(!wedge_db)
	  throw(Error.Generic("foo!\n"));
	  
	  werror("wedge: %O\n", wedge_db);
	return wedge_db->delete(1);
//	werror("deleting " + combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["wedges"], wedgename+ ".xml"));	
}


int delete_matcase(string id, object user)
{
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)id, "owner": user]))[0]);
	if(mca_db)
		return mca_db->delete();
	else return 0;
//    werror("deleting " + combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml") + "\n");
//	return rm(combine_path(getcwd(), config["locations"]["matcases"], matcase + ".xml"));	
}

object load_matcase_by_name(string matcasename)
{
	object mca_db;
	catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": matcasename]))[0]);
	
	if(mca_db)
  	  return Monotype.load_matcase_string(mca_db["xml"]);
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_matcase_dbobj(string matcasename, object user)
{
	object mca_db;
	if(user)
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["name": matcasename, "owner": user]))[0]);
	else
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)matcasename]))[0]);
	
	werror("**** %O\n", mca_db);
	if(mca_db)
  	  return mca_db;
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_matcase_dbobj_by_id(string id, object user)
{
	object mca_db;
	if(user)
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)id, "owner": user]))[0]);
	else
		catch(mca_db = master()->resolv("Fins.Model.find.matcasearrangements")((["id": (int)id]))[0]);
	
	werror("**** %O\n", mca_db);
	if(mca_db)
  	  return mca_db;
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_wedge_dbobj(string wedgename, object user)
{
	object wedge_db;
/*
	if(user)
		catch(wedge_db = master()->resolv("Fins.Model.find.wedges")((["name": wedgename, "owner": user]))[0]);
	else
		
*/
	catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["name": wedgename]))[0]);
	
	werror("**** %O\n", wedge_db);
	if(wedge_db)
  	  return wedge_db;
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

object load_wedge_dbobj_by_id(string id, object user)
{
	object wedge_db;
	if(user)
		catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["id": (int)id, "owner": user]))[0]);
	else
		catch(wedge_db = master()->resolv("Fins.Model.find.stopbars")((["id": (int)id]))[0]);
	
	werror("**** %O\n", wedge_db);
	if(wedge_db)
  	  return wedge_db;
	else return 0;
	
//	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}


object old_load_matcase(string matcasename)
{
	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

array get_mcas()
{
  array m, m2;
  m = master()->resolv("Fins.Model.find.matcasearrangements_all")(master()->resolv("Fins.Model.SortCriteria")("name"));
  m2 = allocate(sizeof(m));
  foreach(m; int i; object mca)
    m2[i] = lower_case(mca["name"]);
  sort(m2, m);
  return m;
//	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array get_wedges()
{
	return master()->resolv("Fins.Model.find.stopbars_all")(master()->resolv("Fins.Model.SortCriteria")("name"));
//	return map(glob("*.xml", get_dir(config["locations"]["wedges"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array old_get_mcas()
{
	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];}) - ({""});
}

array old_get_wedges()
{
	return sort(map(glob("*.xml", get_dir(config["locations"]["wedges"]) || ({})), lambda(string s){return (s/".xml")[0];})) - ({""}); }

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
//   werror("fuser: %O\n", id->misc->session_variables->user);
//  werror("event_name: %O, controller: %O, auth-free? %O\n", id->event_name, id->controller, id->controller[id->event_name]);
   if(is_desktop && !id->misc->session_variables->user)
   {
	 object user = master()->resolv("Fins.Model.find.users_by_alt")("desktop");
	 id->misc->session_variables->user = user;
         populate_user_prefs(user);
   }
   else if(id->controller["_no_auth_" + id->event_name])
   {
     return 1;
   }
   else if(!id->misc->session_variables->user)
   {
      response->flash("msg", "You must login to perform this action.");
      response->redirect_temp(controller->auth->login, 0, ([ "return_to": id->not_query ]));
      return 0;
   }

   return 1;
}

int admin_only_user_filter(Fins.Request id, Fins.Response response, mixed ... args)
{
   werror("fuser: %O\n", id->misc->session_variables->user);
   if(is_desktop && !id->misc->session_variables->user)
   {
	 object user = master()->resolv("Fins.Model.find.users_by_alt")("desktop");
	 id->misc->session_variables->user = user;
         populate_user_prefs(user);
   }
   else if(!id->misc->session_variables->user || !id->misc->session_variables->user["is_admin"])
   {
      response->flash("msg", "You must be an admin user to perform this action.");
      response->redirect_temp(controller->auth->login, 0, ([ "return_to": id->not_query ]));
      return 0;
   }

   return 1;
}

object get_sys_pref(string pref, object user)
{
  Keyboard.Objects.Preference p;
  mixed err = catch(p = Fins.DataSource["_default"]->find->preferences((["name": pref, "User": user])));
  if((err = Error.mkerror(err)) && !err->_is_recordnotfound_error) throw(err);
//werror("prefs for %s %O: %O\n", pref, user, p);
  if(sizeof(p))
    return p[0];
  else return 0;
}

//! @param defs
//!  optional mapping containing keys to set on new object if it doesn't exist already.
object new_string_pref(string pref, object user, string value, mapping|void defs)
{
  mixed p;
  p = get_sys_pref(pref, user);
  if(p) return p;
  else 
  { 
     logger->info("Creating new preference object '" + pref  + "'.");
     p = Keyboard.Objects.Preference();
     p["name"] = pref;
     p["type"] = Keyboard.STRING;
     p["value"] = value;
//     p["description"] = "";
     p["User"] = user;
     if(defs)
     {
       foreach(defs; string k; string v)
         p[k] = v;
     }
     p->save();
     return p;
  }
}

array full_alphabet_elements = 
  ({
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", 
      "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
      "Y", "Z",
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
      "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
      "y", "z",
      "ff", "fi", "fl", "ffi", "ffl", "œ", "œ",
      "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
      ".", ",", ":", ";", "!", "?", "&", "-", "$", "‘", "’"
  });

  array small_caps_elements = 
    ({
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", 
        "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
        "Y", "Z"
    });
    
  void populate_user_prefs(object user)
  {
    new_string_pref("full_sorts_palette_contents", user, 
      full_alphabet_elements * " ");

    new_string_pref("sc_sorts_palette_contents", user, 
         small_caps_elements * " ");
         
    new_string_pref("hyphenation_rules", user, 
         "");
    
  }
  
  
  object save_font_scheme(object font_scheme)
  {
  	string file_name;
  	if(!font_scheme) throw(Error.Generic("No font scheme provided.\n"));

  	font_scheme["updated"] = Calendar.now()->format_http();
//  	if(font_scheme->is_new_object())
  	  font_scheme->save();
    return font_scheme;
  }

  object load_font_scheme(string font_scheme, object|void user)
  {
    object fs;
    if(user)
      catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["name": font_scheme, "owner": user]))[0]);
    else
      catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["id": (int)font_scheme]))[0]);

    if(fs)
      return fs;
    else return 0;
  }

  object load_font_scheme_by_id(string id, object user)
  {
    object fs;
    if(user)
      catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["id": (int)id, "owner": user]))[0]);
    else
      catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["id": (int)id]))[0]);

    if(fs)
      return fs;
    else return 0;
  }

  int delete_font_scheme(string id, object user)
  {
  	object fs;
  	catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["id": (int)id, "owner": user]))[0]);
  	if(fs)
  		return fs->delete();
  	else return 0;
  }

  object load_font_scheme_by_name(string font_scheme)
  {
  	object fs;
  	catch(fs = master()->resolv("Fins.Model.find.font_schemes")((["name": font_scheme]))[0]);

  	if(fs)
    	  return fs;
  	else return 0;
  }

  array get_font_schemes()
  {
    array m, m2;
    m = master()->resolv("Fins.Model.find.font_schemes_all")(master()->resolv("Fins.Model.SortCriteria")("name"));
    m2 = allocate(sizeof(m));
    foreach(m; int i; object fs)
      m2[i] = lower_case(fs["name"]);
    sort(m2, m);
    return m;
  //	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
  }

  int(0..1) font_scheme_exists(string name, object user)
  {
  	array r = master()->resolv("Fins.Model.find.font_schemes")((["name": name, "owner": user]));
  	if(sizeof(r))	
  	  return 1;
  	else return 0;
  }
