inherit Fins.ScaffoldController;

string  model_component = "User";

void start()
{
  ::start();	
  before_filter(app->admin_only_user_filter);
}