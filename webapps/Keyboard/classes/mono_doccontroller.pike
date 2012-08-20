inherit Fins.DocController;


void populate_template(Fins.Request request, Fins.Response response, Fins.Template.View lview, mixed... args)
{
  
//  werror("populate_Template: %O\n", request->misc);
  if(!lview) return;

  lview->add("controller", app->get_path_for_controller(request->controller));

//werror("USER: %O\n", request->misc->session_variables->user["name"])

  if(request->misc->session_variables && request->misc->session_variables->user)
  {  
	werror("USER: %O\n", request->misc->session_variables->user["name"]);
	lview->add("user", request->misc->session_variables->user);
	if(request->misc->session_variables->user["name"] == "Desktop Application")
	  lview->add("is_desktop", 1);
  }
}
