#charset utf8
// represents a line in a job.
// big and little are the calculated justification settings
// spaces is the number of justification spaces
// units is the size of each jusifying space.

import Monotype;

  object generator;
  
	array elements = ({}); 
	array errors = ({});

	int big;
	int little; 
	int spaces; 

        int line_number;
		int line_on_page;
		
	int max_reduction_units;
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
        mapping config;
	
	static mixed cast(string t)
	{
	   if(t!="string") throw(Error.Generic("invalid cast type " + t + ".\n"));
	
		string s = "";
		
		foreach(elements;;mixed e)
		{
                  if(e->character)
  		    s += e->character;
                  else
                    s+= "_";
		}
		return s;
	}
	
	static void create(object _m, object _s, mapping _config, object _g)
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
		min_space_units = m->elements["JS"]->get_set_width() - max_reduction_units;
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
//	werror("justspace: %f\n", justspace);
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

//	  werror("units needed to justify: %f, minimum space units: %d\n", justspace, min_space_units);

	  justspace = justspace + ((min_space_units)-(m->elements["JS"]->get_set_width()));
//	  justspace = justspace + ((min_space_units)-m->elements["JS"]->get_set_width());
//	werror("calculated justification increments: %f->%d\n", justspace, (int)round(justspace));
	  justspace *= (setwidth * 1.537);	
//		  werror("calculated justification increments: %f->%d\n", justspace, (int)round(justspace));

//	  werror("calculated justification increments: %f->%d\n", justspace, (int)round(justspace));

	  int w = ((int)round(justspace)) + 53; // 53 increments of the 0.0005 is equivalent to 3/8.

          int small,large;
          large = w/15;
          small = w%15;
          if(small == 0) large--,small=15;
        
	  return ({ large, small });
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
	void add(string activator, int|void modifier, int|void adjust_space, int|void atbeginning, int|void stealth)
	{
	  object mat;

//werror("Line.add(%O, %O)\n", activator, modifier);
	  // justifying space
	  if(activator == " ")
	  {
		object js = m->elements["JS"];
	    // houston, we have a problem!
	    if(!js) error("No Justifying Space in MCA!\n");

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

 	  if(modifier & MODIFIER_SMALLCAPS && config->allow_lowercase_smallcaps)
          {
		activator = upper_case(activator);
	  }

	  string code = activator;

	  if(modifier&MODIFIER_ITALICS)
	      code = "I|" + code;	 
	  else if(modifier&MODIFIER_SMALLCAPS)
	      code = "S|" + code;
	  else if(modifier&MODIFIER_BOLD)
	      code = "B|" + code;

	  mat = m->elements[code];

       if(!mat && (modifier&MODIFIER_ITALICS) && config->allow_punctuation_substitution && (<".", ",", ":", ";", "'", "’", "‘", "!", "?", "-", "–">)[activator])
      {
	    if(mat = m->elements[activator])
		    errors += ({"Substituted activator " + (activator) + " from roman alphabet."});
		else
		    errors += ({"Unable to substitute activator [" + (activator) + "] from roman alphabet."});
		
      }

	  if(!mat)
      { 
                errors += ({("Requested activator [" + 
			(activator) + "] (" + sprintf("%q", code)+ "), code [" + (code) + "] not in MCA.\n")}); 
		werror("invalid activator %O/%O\n", string_to_utf8(activator),code);
      }
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
		if(!stealth)
 	    	  linelength+=(mat->get_set_width() + adjust_space);
	  }

	if(!stealth)
	  calculate_justification();
//	  if(interactive)
//	    werror("%s %d %s %s\n", displayline * "", lineunits-linelength, can_justify()?("* "+ big + " " + little):"", is_overset()?(" OVERSET "):"");

	}



	int is_overset()
	{
		calculate_justification();
int overset = (linelength > lineunits) ;//|| (linespaces && ((big*15)+little)<((min_big*15)+min_little) );
if(overset)
{
 werror("overset: units in line: %d, lineunits: %d, linespaces: %d, big: %d, little: %d\n", linelength, lineunits, linespaces, big, little);
}
 return overset;
//werror("min_big: %d min_little: %d big: %d little: %d\n", min_big, min_little, big, little);
	}

	int can_justify()
	{
	//	werror("linespaces: %O big: %O little: %O\n", linespaces, big, little);
	  	return(linespaces && ((big <= 15) && (big > 0))  && ((little <= 15) && (little > 0)));
	}
	
	string generate_line()
	{
	  String.Buffer buf = String.Buffer();
	  // a little nomenclature here: c == coarse (0075) f == fine (0005), 
    //   cc == current coarse setting, cf == current fine setting
  	  int cc, cf, c, f; // the current justification wedge settings
  	  f = little;
  	  c = big;
  	  cf = f;
  	  cc = c;

  	  write("\n");
      buf+=sprintf("%s %s %d\n", generator->fine_code, generator->coarse_code, f);
      buf+=sprintf("%s %d\n", generator->coarse_code, c);

            foreach(reverse(elements);; object me)
            {
              if(me->is_real_js)
              {
                // if we've previously changed the justification wedges in order to
                // correct a sort width, we need to put things back.
  	          if(cf != f || cc != c)
  	          {
  		werror("resetting justification wedges.\n");
  		        buf+=sprintf("%s %d\n", generator->fine_code, f);
  		        buf+=sprintf("%s %d\n", generator->coarse_code, c);
  			    cf = f;
  			    cc = c;
  	          }
                buf+=sprintf("S %d %s [ ]\n", me->matrix->row_pos, me->matrix->col_pos);
                werror("_");
            }
            else 
  	      {
  //			werror("ME: %O", mkmapping(indices(me), values(me)));
              string row_pos = me->row_pos;
              string col_pos = me->col_pos;

  	        int wedgewidth;
  	        if(me->row_pos == 16 && ! config->unit_shift)
  			{
  				throw(Error.Generic("Cannot use 16 row matcase without unit shift.\n"));
  			}

  			// get the width of the requested row unless it's 16, which doesn't exist.
  			// in that case, get the width of row 15.
  	 		wedgewidth = s->get(me->row_pos!=16?me->row_pos:15);

  	      //werror("want %d, wedge provides %d\n", mat->get_set_width(), wedgewidth);
  	      if(me->row_pos == 16 || (wedgewidth != me->get_set_width())) // we need to adjust the justification wedges
  	      {
  	        int nf, nc;

  	// TODO: we need to check to make sure we don't try to open the mould too wide.

  		werror("needs adjustment: have %d, need %d!\n", wedgewidth, me->get_set_width());
  	        // first, we should calculate what difference we need, in units of set.
  	        int needed_units = me->get_set_width() - wedgewidth;

  			// at this point, we'd select the appropriate mechanism for handling the difference
  			// presumably, we'd use the following techniques, were they available to us:
  			// 1. unit adding
  			if(config->unit_adding && config->unit_adding == needed_units)
  			{
                buf+=sprintf("0075 ");
  			}

  			// 2. unit shift
  			else if(config->unit_shift && me->row_pos > 1 && (s->get(me->row_pos - 1) == me->get_set_width()))
  			{
  			  row_pos = (me->row_pos - 1);
  			  if(col_pos == "D") col_pos = "EF";
  			  col_pos = "D" + col_pos;
  			}

  			// 3. unit adding + unit shift
  			else if(config->unit_adding && config->unit_shift && me->row_pos > 1 && (me->get_set_width() == (config->unit_adding + s->get(me->row_pos - 1))))
  			{
  			  row_pos = (me->row_pos - 1);
  			  if(col_pos == "D") col_pos = "EF";
  			  col_pos = "D" + col_pos;

                buf+=sprintf("0075 ");			
  			}
  			// 4. underpinning

  			// 5. letterspacing via justification wedge (currently the only technique in use here) 
  	        // then, figure out what that adjustment is in terms of 0075 and 0005
  	        else
  	        {
                  [nc, nf] = calculate_wordspacing_code(needed_units);
  		        // if it's not what we have now, make the adjustment

   		        if(cf != nf || cc != nc)
  		        {
                    buf+=sprintf("%s %d\n", generator->fine_code, nf);
  	              buf+=sprintf("%s %d\n", generator->coarse_code, nc);
                    cf = nf;
  		          cc = nc;
  	            }

  	            buf+=sprintf("S ");
  	         }
  	    }
          string c = me->character;
    	    if(me->is_fs || me->is_js)
  	      c = " ";

        werror(string_to_utf8(c));
  	  buf+=sprintf("%s %s [%s]\n", (string)row_pos, (col_pos/"")*" ", string_to_utf8(c));
    }
   }
   return buf->get();
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
