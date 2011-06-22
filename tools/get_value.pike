

int main(int argc, array argv)
{
	if(argc != 3)
	{
		werror("Usage: %s versionConfigFile keyName\n", argv[0]);
		exit(1);
	}
	
	string inputFile = argv[1];

	string valueToFind = argv[2];
	
	mapping map = ([]);
	
	foreach(Stdio.read_file(inputFile)/"\n"; int ln; string line)
	{	
		array args = ({});	
		foreach(line/"="; int i; string x)
		  args += ({String.trim_all_whites(x)});
		if(sizeof(args) != 2)
		{
		  werror("error in line %d of version config file %s.\n", ln, inputFile);
		  exit(1);
		}
		
		map[args[0]] = args[1];
		
	}
	
	write(map[valueToFind] + "\n");
	
	return 0;
}