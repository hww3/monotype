
inherit Fins.DocController;

object mca;
object wedge;
object ribbon;

object auth;

object dojo;

void start()
{
  wedge = load_controller("wedge");
  mca = load_controller("mca");
  ribbon = load_controller("ribbon");
  dojo = Fins.StaticController(app, "dojo");
  auth = load_controller("auth/controller");

  before_filter(app->admin_user_filter);
}



void index(object id, object response, mixed ... args)
{
}
