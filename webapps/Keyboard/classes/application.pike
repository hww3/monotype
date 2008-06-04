
inherit Fins.Application;

void save_matcase(Monotype.MatCaseLayout mca)
{
	string file_name;
	object node = mca->dump();
	file_name = combine_path(getcwd(), config["locations"]["matcases"], mca->name  + ".xml");
	mv(file_name, file_name + ".bak");
	Stdio.write_file(file_name, Public.Parser.XML2.render_xml(node));
}

object load_wedge(string wedgename)
{
	return Monotype.load_stopbar(combine_path(getcwd(), config["locations"]["wedges"], wedgename));	
}

object load_matcase(string matcasename)
{
	return Monotype.load_matcase(combine_path(getcwd(), config["locations"]["matcases"], matcasename));
}

array get_mcas()
{
	return map(glob("*.xml", get_dir(config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});
}

array get_wedges()
{
	return map(glob("*.xml", get_dir(config["locations"]["wedges"]) || ({})), lambda(string s){return (s/".xml")[0];});
}