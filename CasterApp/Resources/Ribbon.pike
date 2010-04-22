
Stdio.FILE file;

int current_pos = 0;
int current_line = 0;
multiset current_code, last_code;
int body_start;

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
	body_start = pos;
	int total_lines, total_codes;
	multiset last;
	foreach(file;int i;string l)
	{
		// we're looking for 0005+0075 followed by a 0075 code (end of line and reset).
        // 0005 followed by 0075 is used in double justification.
		multiset c = (multiset)((l/" ")-({""}));
		if(c["0075"] && (last && last["0005"] && last["0075"])) total_lines++;
		if(!sizeof(c)) continue;
		last = c;
		total_codes ++;
	}

	job_info->code_count = total_codes + 1;
	job_info->line_count = total_lines;
	
	file->seek(pos);
}

void parse_header()
{
	string s;
	
	do
	{
		s = file->gets();
		catch(s = String.trim_all_whites(s));

		if(s && sizeof(s))
		{
			array l = array_sscanf(s, "%s: %s");
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
		file->seek(body_start);
		current_pos = 0;
		current_line = 0;
	}
}

array low_get_next_code()
{
  catch
  {
	string line = file->gets();
//	werror("LINE: %O\n", line);
    if(!line)
  	  return 0;
  //  werror("code is %O\n", line);
    if(!sizeof(line)) return 0;
     
    sscanf(line, "%s [%s\]", line, string character);
    return sizeof(line)?(line / " "):0;
  };

  return 0;
}

array low_get_previous_code()
{
  catch
  {
	string line = file->rgets();
//	werror("LINE: %O\n", line);
    if(!line)
  	  return 0;
  //  werror("code is %O\n", line);
    if(!sizeof(line)) return 0;
     
    sscanf(line, "%s [%s\]", line, string character);
    return sizeof(line)?(line / " "):0;
  };

  return 0;
}

array get_next_code()
{
	last_code = current_code;
	array code = low_get_next_code();
	if(code)
	{
  	  current_code = (multiset)code;
      current_pos++;
	  if(current_code && current_code["0075"] && current_code["0005"])
	  {
		current_line++;
	  }
    }
    else 
      current_code = 0;
	return code;
}


array get_previous_code()
{
	current_code = last_code;
	array code = low_get_previous_code();
	if(code)
	{
  	  last_code = (multiset)code;
      current_pos--;
	  if(last_code && last_code["0075"] && last_code["0005"])
	  {
		current_line--;
	  }

    }
    else 
      current_code = 0;
	return code;
}


void skip_to_line_beginning()
{
	do
	{
	  get_previous_code();
	  if(! last_code)
	  {
		// we must be at the full beginning.
		current_line=0;
		return;
	  }
	  else
	  {
		if(last_code["0075"] && last_code["0005"])
		  return;
	  }
	} while(1);
}

void skip_to_line_end()
{	
	do
	{
		get_next_code();
//		werror("current_code: %O\n", current_code);
		if(!current_code) return; // at the end of the ribbon.
		else if(current_code["0075"] && current_code["0005"]) // line ended.
		{
			// we want to have both the 0075-0005 and 0005 code sequences, so we put the line end back.
			current_code = last_code;
			last_code = 0;
			current_line--;
			return_code();
			return;
		}
	}
	while(1);
}

void return_code()
{
	file->rgets();
	current_pos --;
}
