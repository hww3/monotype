
inherit Fins.FinsView;
inherit Fins.Helpers.Macros.Basic;
inherit Fins.Helpers.Macros.Pagination;

static void create(object app)
{
  ::create(app);
}

program default_template = Fins.Template.ePike;

string simple_macro_matrix(Fins.Template.TemplateData data, mapping|void args)
{
	mixed d = data->get_data();
	object matrix = get_var_value(args["mca"], d)->get(get_var_value(args["col"], d),(int)get_var_value(args["row"], d));
	data->add(args["val"], matrix);
	return ""; // sprintf("%O", d);
}
