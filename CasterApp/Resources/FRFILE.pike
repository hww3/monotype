inherit Stdio.FILE;

static mixed create(mixed ... args)
{
	::create(@args);
	//size = seek(-1);
	//seek(0);
	//count_lines();
}

// reads the previous line from the file. 
string rgets()
{
	int stop;
	int opos = tell();
	int cpos = opos;
	string buf = "";
	
	do
	{
	  if(cpos == 0)
	     return 0;
	  if(cpos < 80) 
	     cpos = seek(0);
	  else 
	     cpos = seek(cpos - 80);
	  buf = read(opos-cpos < 80? opos-cpos : 80) + buf;
// werror("buf: %O\n", buf);

	  int start, end;
      int nlc = 0;

      for(int i = sizeof(buf)-1; i >= 0; i--)
      {
	     if(buf[i] == '\n')
	     {
	//	werror("got a newline.\n");
	       nlc++;
  	       if(nlc == 1)
	         end = i-1;
	       else if(nlc == 2)
	       {
              start = i+1;
              seek(cpos+start);
             // werror("start: %d end: %d\n", start, end);
              return buf[start..end];
           }
        }
    }
        if(cpos == 0 && nlc == 1) // from beginning of the file, to the end.
        {
			seek(0);
           return buf[..end];
		}
	} 
	while(!stop);
}

int count_lines()
{
	int pos;
	int line;
	int total_lines;
    pos = tell();
	foreach(this;line;)
       total_lines = line;
    seek(pos);
    return total_lines+1;
}

