import Fins;

inherit "mono_doccontroller";

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
}

void index(object id, object response, mixed ... args)
{
}

void save(object id, object response, mixed ... args)
{
	response->flash("Preferences Saved.");
	response->redirect(index);
}