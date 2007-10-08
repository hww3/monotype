inherit Stdio.FILE;

static mixed create(mixed ... args)
{
	::create(@args);
	//size = seek(-1);
	//seek(0);
	//count_lines();
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

