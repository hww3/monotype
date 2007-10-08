
Stdio.FILE file;

int current_pos = 0;

mapping job_info = ([]);


static void create(string filename)
{
	if(!file_stat(filename))
	  throw(Error.Generic("Ribbon file " + filename + " does not exist.\n"));

	file = ((program)"FRFILE")(filename, "r");
	
	parse_header();
	job_info->code_count = file->count_lines();
	parse_body();
}

void parse_body()
{
	int pos = file->tell();
	int total_lines, total_codes;
	multiset last;
	foreach(file;int i;string l)
	{
		// we're looking for 0005+0075 followed by a 0075 code (end of line and reset).
        // 0005 followed by 0075 is used in double justification.
		multiset c = (multiset)((l/" ")-({""}));
		if(c["0075"] && (last && last["0005"] && last["0075"])) total_lines++;
		last = c;
		total_codes ++;
	}

	job_info->code_count = total_codes + 1;
	job_info->line_count = total_lines + 1;
	
	file->seek(pos);
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
	string line = file->gets();
	werror("LINE: %O\n", line);
    if(!line)
  	  return 0;
  //  werror("code is %O\n", line);
    if(!sizeof(line)) return 0;
     
    sscanf(line, "%s [%s\]", line, string character);
    return sizeof(line)?(line / " "):0;
  };

  return 0;
}