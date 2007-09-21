
Stdio.FILE file;

array codes;

int current_pos = 0;

mapping job_info = ([]);


static void create(string filename)
{
	if(!file_stat(filename))
	  throw(Error.Generic("Ribbon file " + filename + " does not exist.\n"));

	file = Stdio.FILE(filename, "r");
	
	parse_header();
	parse_body();
}

void parse_body()
{
	codes = file->read()/"\n";
}

void parse_header()
{
	string s;
	
	do
	{
		s = file->gets();
		
		if(s && sizeof(s))
		{
			array l = s / ":";
			if(sizeof(l) != 2) throw(Error.Generic("Invalid header " + s + "\n"));
			job_info[String.trim_whites(lower_case(l[0]))] = String.trim_whites(l[1]);
		}
	} while (s && sizeof(s));
}

mapping get_info()
{
	return job_info + ([]);
}

void rewind(int where)
{
	if(where == -1)
	{
		current_pos = 0;
	}
}

array get_next_code()
{
  catch
  {
	string line = codes[current_pos++];
    if(!line)
  	  return 0;
    werror("code is %O\n", line);
    return (line / " ");
  };

  return 0;
}