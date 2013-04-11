#charset utf8

import Fins;

inherit "mono_doccontroller";

int __quiet = 1;
    
void start()
{
  before_filter(app->admin_user_filter);
}

void index(object id, object response, object view, mixed ... args)
{
 // app->new_string_pref("sorts_palette_location", id->misc->session_variables->user, "top");
 
  mixed x = id->misc->session_variables->user["Preferences"];
  
  werror("x: %O\n", (mapping)x);
  view->add("preferences", (mapping)x);
}

void save(object id, object response, object view, mixed ... args)
{
  mixed x = id->misc->session_variables->user["Preferences"];
  mixed p = x[id->variables->pref_name];
  if(!p) response->flash("Preference Not Found (" + id->variables->pref_name + ").");
	p["value"] = id->variables->pref;
//	p->save();
	response->flash("Preference Saved.");
	response->redirect(index);
}