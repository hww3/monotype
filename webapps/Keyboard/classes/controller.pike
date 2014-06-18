inherit Fins.RootController;
inherit "mono_doccontroller";

object mca;
object wedge;
object ribbon;
object font_scheme;

object auth;
object users;
object prefs;

object cloud;

object dojo;

protected void create(object application)
{
  ::create(application);
}

void start()
{
  wedge = load_controller("wedge");
  mca = load_controller("mca");
  ribbon = load_controller("ribbon");
  dojo = Fins.StaticController(app, "dojo");
  auth = load_controller("auth/controller");
  users = load_controller("users");
  prefs = load_controller("prefs");
  cloud = load_controller("cloud");

  font_scheme = load_controller("font_scheme");
  
  before_filter(app->admin_user_filter);
}



void index(object id, object response, mixed ... args)
{
}

void info(object id, object response, object v, mixed ... args)
{
#if constant(Public.Tools.Language.Hyphenate)
  v->add("hyphenation", 1);
#endif
  v->add("hw", Process.popen("uname -m"));
  v->add("node", Process.popen("uname -n"));
  v->add("arch", Process.popen("uname -p"));
  v->add("rel", Process.popen("uname -r"));
  v->add("sys", Process.popen("uname -s"));
  v->add("ver", Process.popen("uname -v"));
  v->add("pike", version());
}

void changes(object id, object response, object v, mixed ... args)
{
	v->add("changes" , Stdio.read_file("CHANGES"));
}

void _backup_db(object id, object response, object v, mixed ... args)
{
  if(id->variables->destination)
  {
werror("REMOTE: %O\n", id->remoteaddr);
    if(!has_prefix(id->remoteaddr, "127.0.0.1"))
    {
      response->set_data("ERROR");
      return;
    }
    string src = master()->resolv("Fins.DataSource._default")->path;
    string dest = id->variables->destination;
    werror("Copying database from %O to %O\n", src, dest);
    Stdio.cp(src, dest);    
    response->set_data("OK");
  }
}
