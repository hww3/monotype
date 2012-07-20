inherit Fins.RootController;
inherit "mono_doccontroller";

object mca;
object wedge;
object ribbon;

object auth;
object users;
object prefs;

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

  before_filter(app->admin_user_filter);
}



void index(object id, object response, mixed ... args)
{
}

void changes(object id, object response, object v, mixed ... args)
{
	v->add("changes" , Stdio.read_file("CHANGES"));
}
