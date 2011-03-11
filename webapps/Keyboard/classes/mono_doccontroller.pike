inherit Fins.DocController;


void populate_template(Fins.Request request, Fins.Response response, Fins.Template.View lview, mixed args)
{
  if(!lview) return;

  if(request->misc->session_variables && request->misc->session_variables->user)
    lview->add("user", request->misc->session_variables->user);
}
