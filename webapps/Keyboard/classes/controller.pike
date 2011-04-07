
inherit "mono_doccontroller";

object mca;
object wedge;
object ribbon;

object auth;
object users;

object dojo;

void start()
{
  wedge = load_controller("wedge");
  mca = load_controller("mca");
  ribbon = load_controller("ribbon");
  dojo = Fins.StaticController(app, "dojo");
  auth = load_controller("auth/controller");
  users = load_controller("users");

  before_filter(app->admin_user_filter);
}



void index(object id, object response, mixed ... args)
{
}
