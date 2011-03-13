inherit Fins.DocController;


void populate_template(Fins.Request request, Fins.Response response, Fins.Template.View lview, mixed args)
{
  
  werror("populate_Template: %O\n", request->misc);
  if(!lview) return;

  if(request->misc->session_variables && request->misc->session_variables->user)
    lview->add("user", request->misc->session_variables->user);
}
