// represents a line in a job.
// big and little are the calculated justification settings
// spaces is the number of justification spaces
// units is the size of each jusifying space.

import Monotype;

	array elements = ({}); 
	array errors = ({});

	int big;
	int little; 
	int spaces; 

	int min_space_units;
	int min_little;
	int min_big;	

	// set to true if the line has been broken using hyphenation.
	int is_broken;
	
	// the calculated size of each justifying space, in units.
	float units;
	
	// the number of justifying spaces on this line.
	int linespaces; 
	
	// the current number of units set on this line.
	int linelength; 
	
	// the total length of the line in units of set.
	int lineunits; 
	
	// the set width of the current face/wedge.	
	float setwidth;
	
	object m, s;
	
	static void create(object _m, object _s, mapping config)
	{
		m = _m;
		s = _s;
		min_little = config->min_little||1;
		min_big = config->min_big||1;
		
		setwidth = config->setwidth;
		lineunits = config->lineunits;		
		min_space_units = m->elements["JS"]->get_set_width() - 2;
	}
	
	// remove a sort from the line; recalculate the justification
	object remove()
	{
	//	werror("calling remove()\n");
//	   displayline = displayline[..sizeof(displayline)-2];
	   if(elements[-1]->is_real_js)
	   {
		 linespaces--;
	     linelength -= (min_space_units);
	   }
	   else
	     linelength -= elements[-1]->get_set_width();

	   object r = elements[-1];
	   elements = elements[0..sizeof(elements)-2];	

	   calculate_justification();

	   return r;
	}
	void calculate_justification()
	{
	  float justspace;

	  justspace = calc_justspace();
	  units = justspace;
	
	  [big, little] = low_calculate_justification(justspace);
	}

	float calc_justspace(int|void verbose)
	{
	  float justspace = 0.00;

	  if(linespaces)
	  {
		// algorithm from page 14
	    justspace = ((float)(lineunits-linelength)/linespaces); // in units of set.
	//	if(verbose)
		//werror("%f = (%d - %d) / %d\n", justspace, lineunits, linelength, linespaces);
	  }

	  return justspace;
	}

	array low_calculate_justification(float justspace)
	{
	  justspace = justspace + ((min_space_units)-m->elements["JS"]->get_set_width());
	  justspace *= (setwidth * 1.537);	

	  int w = ((int)round(justspace)) + 53; // 53 increments of the 0.0005 is equivalent to 3/8.

	  return ({ w/15, w%15 });
	}

	// calculates the large (0.0075) and small (0.0005) justification settings
	// required to add units to the current sort.
	array calculate_wordspacing_code(int units)
	{
		// algorithm from page 25
		int steps = (int)round((0.0007685 * setwidth * units) / 0.0005);
		steps += 53; // 53 is 3/8 code.
		// TODO: check to see if we are opening too wide for the mould.
		
		return ({steps/15, steps%15});
	}


	// add a sort to the current line
	void add(string activator, int|void modifier, int|void adjust_space, int|void atbeginning)
	{
	  object mat;

	  // justifying space
	  if(activator == " ")
	  {
		object js = m->elements["JS"];
	    // houston, we have a problem!
	    if(!js) error("No Justifying Space!\n");

		if(atbeginning)
		{
//			displayline = ({" "}) + displayline;
			elements = ({RealJS(js)}) + elements;
		}
		else
		{
//		    displayline += ({" " });
		    elements += ({RealJS(js)});		
		}
	    linelength += (min_space_units);
	    linespaces ++;
		return;
	  }
/*
	  else if(activator == "\n")
	  {
		new_line();
	    return;
	  }
*/
	  string code = activator;
	  if(modifier&MODIFIER_ITALICS)
	      code = "I|" + code;	 
	  else if(modifier&MODIFIER_SMALLCAPS)
	      code = "S|" + code;
	  else if(modifier&MODIFIER_BOLD)
	      code = "B|" + code;

	  mat = m->elements[code];

	  if(!mat){ errors += ({("invalid activator " + string_to_utf8(activator) + "!\n")}); werror("invalid activator %O", activator);}
	  else
	  {	
		if(atbeginning)
		{
//			displayline = ({activator}) + displayline;
			elements = ({MatWrapper(mat, adjust_space)}) + elements;
		}
		else
		{
//		    displayline += ({ activator });
		    elements += ({MatWrapper(mat, adjust_space)});		
		}
	    linelength+=(mat->get_set_width() + adjust_space);
	  }

	  calculate_justification();
//	  if(interactive)
//	    werror("%s %d %s %s\n", displayline * "", lineunits-linelength, can_justify()?("* "+ big + " " + little):"", is_overset()?(" OVERSET "):"");

	}



	int is_overset()
	{
		calculate_justification();
//werror("min_big: %d min_little: %d big: %d little: %d\n", min_big, min_little, big, little);
		return (linelength > lineunits) || (linespaces && ((big*15)+little)<((min_big*15)+min_little) );
	}

	int can_justify()
	{
	//	werror("linespaces: %O big: %O little: %O\n", linespaces, big, little);
	  	return(linespaces && (big < 15) && (little < 15));
	}
	
	class MatWrapper
	{
		int adjust_space;
		object mat;
		
		static void create(object _mat, int _adjust_space)
		{
			mat = _mat;
			adjust_space = _adjust_space;
		}
		
		static mixed `[](mixed a)
		{
			mixed m = ::`[](a);
			if(m) return m;
			else return mat[a];
		}
		
		int get_set_width()
		{
			return adjust_space + mat->get_set_width();
		}
		
		
		static mixed `->(mixed a)
		{
			mixed m = ::`->(a);
			if(m) return m;
			else return mat[a];
		}
	}
