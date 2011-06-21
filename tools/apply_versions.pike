

int main(int argc, array argv)
{
	if(argc != 3)
	{
		werror("Usage: %s versionConfigFile pathToConfigure\n", argv[0]);
		exit(1);
	}
	
	string inputFile = argv[1];
	string folder = argv[2];
	
	object f = Tools.Standalone.rsif();
	f->recursive = 1;
	f->verbosity = 1;
	
	foreach(Stdio.read_file(inputFile)/"\n"; int ln; string line)
	{	
		array args = ({});
		if(!sizeof(String.trim_all_whites(line))) continue;	
		foreach(line/"="; int i; string x)
		  args += ({String.trim_all_whites(x)});
		if(sizeof(args) != 2)
		{
		  werror("error in line %d of version config file %s.\n", ln, inputFile);
		  exit(1);
		}
		
		args[0] = "${" + args[0] + "}";
		
		f->process_path(folder, @args);		
	}
	
	return 0;
}