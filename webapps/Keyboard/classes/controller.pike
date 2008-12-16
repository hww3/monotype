
inherit Fins.FinsController;

object mca;
object wedge;
object ribbon;

object dojo;

void start()
{
  wedge = load_controller("wedge");
  mca = load_controller("mca");
  ribbon = load_controller("ribbon");
  dojo = Fins.StaticController(app, "dojo");
}

void index(object id, object response, mixed ... args)
{
  object v = view->get_view("index");

  response->set_view(v);
}
