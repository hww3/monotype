
object generator;

array elements = ({}); 
object errors = ADT.List();

// determines whether a line ends with a galley trip justification code.
int double_justification = 0;

int non_spaces;

// set to true if the line has been broken using hyphenation.
int is_broken;

// the calculated size of each justifying space, in units.
float units;

// the number of justifying spaces on this line.
int linespaces; 

// the current number of units set on this line.
float linelength; 

// the total length of the line in units of set.
int lineunits; 

// the set width of the current face/wedge.	
float setwidth;

object m, s;
mapping config;

	protected mixed cast(string t)
	{
	   if(t!="string") throw(Error.Generic("invalid cast type " + t + ".\n"));
	
		string s = "";
		
		foreach(elements;;mixed e)
		{
		  object mat;
		  if(e->get_mat)
  		  mat = e->get_mat(ADT.List());
		  
      if(mat && mat->character)
  	    s += mat->character;
      else
        s+= "_";
		}
		return s;
	}
	
	void re_set_line(object line)
	{
	  foreach(line->elements; int i; object e)
	    add(e);
	}
	
	protected void create(object _m, object _s, mapping _config, object _g)
	{
    config = _config;
		m = _m;
		s = _s;
		generator = _g;
		min_little = config->min_little||1;
		min_big = config->min_big||1;
		
		setwidth = config->setwidth;
		lineunits = config->lineunits;		
		if(!m->elements["JS"])
		  throw(Error.Generic("MCA " + m->name + " has no Justifying Space.\n"));
//		min_space_units = 4; // per page 15
		if(setwidth <= 12.0)
			max_reduction_units = 2;
		else
			max_reduction_units = 1;
	  if(config->combined_space)
	  {
      combined_space = 1;
	    min_space_units = 0;
    }
    else
		  min_space_units = m->elements["JS"]->get_set_width() - max_reduction_units;
	}