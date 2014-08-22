import Fins;
inherit "mono_doccontroller";

int __quiet = 1;

private object c = Protocols.XMLRPC.Client("https://monotype.welliver.org/cloud/");

void start()
{
  before_filter(app->admin_user_filter);
  after_filter(Fins.Helpers.Filters.Compress());
}

public void index(Request id, Response response, Template.View v, mixed ... args)
{
	return;
}


public void connect(Request id, Response response, Template.View v, mixed ... args)
{
  string token = c["login"](id->variables->username, id->variables->password)[0];
  
  if(!token)
  {
    response->flash("msg", "Unable to login. Check your credentials and try again.");
    response->redirect(index);
    return;
  }
  
  id->misc->session_variables->token = token;

  array x = c["list_mcas"](id->misc->session_variables->token)[0];
  
  if(!x || !sizeof(x))
  {
    response->flash("msg", "Unable to fetch MCAs from Cloud.");
    response->redirect(index);
    return;
  }
  
  id->misc->session_variables->cloudmcas = x;
  response->redirect(sync);
  
  return;
} 

public void sync(Request id, Response response, Template.View v, mixed ... args)
{
  array x = id->misc->session_variables->cloudmcas;
  
  if(!x)
  {
    response->flash("msg", "No MCAs found. Please try again.");
    response->redirect(index);
    return;
  }
  
  array cloudnew = ({});
  array cloudupdated = ({});
  array mynew = ({});
  array myupdated = ({});
  
  foreach(x;; mapping mcadata)
  {
      object m = app->load_matcase_dbobj(mcadata->name, id->misc->session_variables->user);
      if(!m) cloudnew += ({mcadata});
      else if(m && ( !m["updated"] || Calendar.dwim_time(mcadata->updated) > Calendar.dwim_time(m["updated"])))
        cloudupdated += ({mcadata});
      else if(m && Calendar.dwim_time(mcadata->updated) < Calendar.dwim_time(m["updated"]))
        myupdated += ({mcadata});
  }
  
  foreach(id->misc->session_variables->user["mcas"];; object mca)
  {
    int gotit;
    string mcn = mca["name"];
    foreach(x;; mapping m)
      if(m->name == mcn)
      {
        gotit = 1;
        break;
      }
    if(!gotit) mynew += ({mca});
  }
  
  v->add("cloudnew", cloudnew);
  v->add("cloudupdated", cloudupdated);
  v->add("mynew", mynew);
  v->add("myupdated", myupdated);
  
  id->misc->session_variables->cloudnew = cloudnew;
  id->misc->session_variables->cloudupdated = cloudupdated;
  id->misc->session_variables->mynew = mynew;
  id->misc->session_variables->myupdated = myupdated;
  
	return;
}

public void results(Request id, Response response, Template.View v, mixed ... args)
{
  
}

public void dosync(Request id, Response response, Template.View v, mixed ... args)
{
  object msgs = ADT.List();
   foreach(({"cloudnew", "cloudupdated", "mynew", "myupdated"});; string bit)
   {
     if(id->variables[bit]=="1")
     {
       switch(bit)
       {
         case "cloudnew":
           pullMCAs(id->misc->session_variables->cloudnew, id, response, msgs);
           break;
         case "cloudupdated":
           pullMCAs(id->misc->session_variables->cloudupdated, id, response, msgs);
           break;
         case "mynew":
           pushMCAs(id->misc->session_variables->mynew, id, response, msgs);
           break;
         case "myupdated":
           pushMCAs(id->misc->session_variables->myupdated, id, response, msgs);
           break;
       }
     }
   }
   
   response->flash("msg", (array)msgs*"<br>");  
   response->redirect(results);
}

private void pullMCAs(array mcas, object id, object response, object msgs)
{
  foreach(mcas;; mapping md)
  {
    mapping x = c["get_mca"](id->misc->session_variables->token, md->id)[0];
    if(!x)
    {
      response->flash("msg", "Unable to fetch MCA " + md->name +". Please try again.");
      response->redirect(index);
      return;
    }
    object mcao = Monotype.load_matcase_string(x["xml"]);
    app->save_matcase(mcao, id->misc->session_variables->user, -1, Calendar.dwim_time(md["updated"]));
    msgs->append("Loaded " + md["name"] + ".");
  }
}

private void pushMCAs(array mcas, object id, object response, object msgs)
{
  
  werror("mcas to push: %O", mcas);
  foreach(mcas;; mixed md)
  {
    object x = app->load_matcase_dbobj(md["name"], id->misc->session_variables->user);
    werror("mca: %O\n", x);
    if(!x)
    {
      response->flash("msg", "Unable to load MCA " + md["name"] +". Please try again.");
      response->redirect(index);
      return;
    }
    
    mixed res = c["put_mca"](id->misc->session_variables->token, x["xml"], x["updated"]);
    werror("RES: %O\n", res);
    if(res && res[0])
      msgs->append("Pushed " + md["name"] + ".");
    else
      msgs->append("Unable to push " + md["name"] + ".");
  }
}

