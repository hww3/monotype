import Fins;

inherit "mono_doccontroller";

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
}
