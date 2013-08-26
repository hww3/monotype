#charset utf8
// represents a line in a job.
// big and little are the calculated justification settings
// spaces is the number of justification spaces
// units is the size of each jusifying space.

import Monotype;

  object generator;
  
	array elements = ({}); 
	object errors = ADT.List();

	int big;
	int little; 
	int spaces; 

  int finalized;
  
  int line_number;
	int line_on_page;
	
	int combined_space;
//	float calculated_justifying_space = 0.0;
		
	int max_reduction_units;
	int min_space_units;
	int min_little;
	int min_big;	

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
	
	int max_ls_adjustment = 2;
	
	static mixed cast(string t)
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
	  if(config->combined_space)
	  {
      combined_space = 1;
	    min_space_units = 0;
    }
    else
		  min_space_units = m->elements["JS"]->get_set_width() - max_reduction_units;
	}
	
	int hyphenation_disabled()
	{
	  if(!sizeof(elements)) // can't hyphenate an empty line...
	    return 1;
	  else return elements[-1]->hyphenation_disabled;
	}
	
	// remove a sort from the line; recalculate the justification
	object remove()
	{
	  object r;
	  if(!sizeof(elements))
	    return 0;
  	  r = elements[-1];
	//	werror("calling remove()\n");
//	   displayline = displayline[..sizeof(displayline)-2];
	   if(r->is_real_js)
	   {
		 linespaces--;
	     linelength -= (min_space_units);
	   }
	   else
	     linelength -= r->get_set_width();

	   elements = elements[0..sizeof(elements)-2];	

	   [big, little] = calculate_justification();

	   return r;
	}
	array calculate_justification(int|float|void mylinelength)
	{
	  float justspace;

	  justspace = calc_justspace(0, mylinelength);
	  if(!mylinelength)
 	    units = justspace;
//	werror("justspace: %f\n", justspace);
	  return low_calculate_justification(justspace);
	}

	float calc_justspace(int|void verbose, int|float|void mylinelength)
	{
	  float justspace = 0.00;

	  if(linespaces)
	  {
		// algorithm from page 14
		justspace = (((float)(lineunits)-get_line_length(mylinelength))/linespaces); // in units of set.
	  //  justspace = ((float)(lineunits-get_line_length(mylinelength))/linespaces); // in units of set.
	//	if(verbose)
	//	werror("%f = (%O - %O) / %d\n", justspace, lineunits, linelength, linespaces);
	  }

	  return justspace;
	}


//
//
//  TODO
//  TODO
//  TODO  We need to figure out a way to get this ajustment to be applied _only_ when checking for oversetness, 
//  TODO  rather than for when we're actually calculating justification codes.
//  TODO
//  TODO  Perhaps we've solved this by using the 'finalized' attribute?
//  TODO
//
//
	
	float get_line_length(float|int|void mylinelength)
	{
	  float ll = (float)(mylinelength||linelength);
	  if(config->hanging_punctuation && config->hanging_punctuation_width && sizeof(elements) && m->is_punctuation(elements[-1]->character))
	    return ll;
	  else if(finalized)
	    return ll;
	  else return ll +  config->hanging_punctuation_width; // this is okay if we're not doing hanging punctuation, as the value would be 0.
	}

	array low_calculate_justification(float justspace)
	{
//werror("calculate justification: %f\n", justspace);

	  justspace = justspace + ((min_space_units)-(m->elements["JS"]->get_set_width()));
	  
	  return really_low_calculate_justification(justspace);
	}
	
	array really_low_calculate_justification(float justspace)
	{
	  int small,large;
    
	  justspace *= (setwidth * 1.537);	

	  int w = ((int)round(justspace)) + 53; // 53 increments of the 0.0005 is equivalent to 3/8.

      large = w/15;
      small = w%15;
      if(small == 0) large--,small=15;
        
	  return ({ large, small });
	}

	// calculates the large (0.0075) and small (0.0005) justification settings
	// required to add units to the current sort.
	array calculate_wordspacing_code(float units)
	{
		// algorithm from page 25
		int steps = (int)round((0.0007685 * setwidth * units) / 0.0005);
		steps += 53; // 53 is 3/8 code.
		// TODO: check to see if we are opening too wide for the mould.
		array x = ({steps/15, steps%15});
		if(x[1] == 0)
		{
		  x[0]--;
		  x[1]=15;
		}
		if(x[0] > 15 || x[0] < 1) throw(Error.Generic(sprintf("Bad Justification code %d/%d\n", x[0], x[1])));
		if(x[1] > 15 || x[1] < 1) throw(Error.Generic(sprintf("Bad Justification code %d/%d\n", x[0], x[1])));
		return x;
	}


	// add a sort to the current line
	void add(Sort|RealJS activator, int|void atbeginning, int|void stealth)
	{
	  object mat;

//werror("Line.add(%O, %O)\n", activator, atbeginning);
// justifying space
    if(activator->is_real_js)
    {
	    if(atbeginning)
	    {
		    elements = ({activator}) + elements;
	    }
	    else
	    {
	      elements += ({activator});		
	    }
      linelength += (min_space_units);
      linespaces ++;
	    return;
    }
    else if(mat = activator->get_mat(errors))
	  {
	    if(!stealth)
 	  	  linelength+=(mat->get_set_width() + activator->space_adjust);
 	  	 
  		if(atbeginning)
  	  {
  		  elements = ({activator}) + elements;
  		}
  	  else
  	  {
  		  elements += ({activator});		
  	  }    
    }

	  if(!stealth)
	    [big, little] = calculate_justification();
	}

  // can we add n units to the line and still meet the justification requirements?
  int can_add(float units)
  {
	return !is_overset(linelength + units);
  }

  int is_overset(float|void mylinelength)
  {
    int mbig, mlittle;
    catch {
      if(!combined_space)
        [mbig, mlittle] = calculate_justification(mylinelength);
      else
      {
        float cjs = calc_justspace(0, mylinelength);
        [mbig, mlittle] = calculate_wordspacing_code(cjs);
        //calculated_justifying_space = cjs;
      }
    };
    int overset = get_line_length(mylinelength) > lineunits ;//|| (linespaces && ((mbig*15)+mlittle)<((min_big*15)+min_little) );

    overset = overset || (linespaces && ((mbig*15)+mlittle)<((min_big*15)+min_little));
    if(overset)
    {
      werror("overset: # %d => line length: %d, units in line: %.1f, to add: %.1f, linespaces: %d, just: %d/%d min: %d/%d\n", line_number, lineunits, linelength, (float)mylinelength, linespaces, mbig, mlittle, min_big, min_little);
    }

    if(!mylinelength)
    {
      big = mbig, little = mlittle;
    }

    return overset;
  }

	int can_justify()
	{
	//	werror("linespaces: %O big: %O little: %O\n", linespaces, big, little);
	  	return(linespaces && ((big <= 15) && (big > 0))  && ((little <= 15) && (little > 0)));
	}
	
	array render_line()
	{
	//  errors = ADT.List();
	  int i;
	  array x = allocate(sizeof(elements));
	  foreach(elements;;mixed e)
	  {
	    mixed matrix;
	    if(e->is_real_js)
	    {
	      x[i] = e;
	      i++;
	    }
	    else if(matrix = e->get_mat(errors))
	    {
	      x[i] = MatWrapper(matrix, e->space_adjust);
  	    i++;
	    }
	    else
	    {
	      werror("skipping %O\n", e);
	    }
	  }
	  
	  if(i)
  	  return x[0 .. i-1];
  	else return ({});
	}
	
	string generate_line()
	{
	  int last_space;
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

      foreach(reverse(render_line());; object me)
      {
        int this_combined_space = 0;
        
        if(last_space && combined_space)
        {
          if(cf != f || cc != c)
  	      {
  		      werror("resetting justification wedges: %O %O.\n", f, c);
  		      buf+=sprintf("%s %d\n", generator->fine_code, f);
  		      buf+=sprintf("%s %d\n", generator->coarse_code, c);
  			    cf = f;
  			    cc = c;
  	      }
  	      this_combined_space = 1;
          last_space = 0;
        }
        if(me->is_real_js && combined_space)
        {
          last_space = 1;
          continue;
        }
        else if(me->is_real_js)
        {
          // if we've previously changed the justification wedges in order to
          // correct a sort width, we need to put things back.
  	      if(cf != f || cc != c)
  	      {
  		      werror("resetting justification wedges: %O %O.\n", f, c);
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
  			  
  			  if(config->unit_shift)
  			  {
  			    col_pos = replace(col_pos, "D", "EF");
  			  }

  			  // get the width of the requested row unless it's 16, which doesn't exist.
  			  // in that case, get the width of row 15.
	//		werror("need wedge width for row %d\n", me->row_pos!=16?me->row_pos:15);
  	 		  wedgewidth = s->get(me->row_pos!=16?me->row_pos:15);
			
  	   //     werror("want %d, wedge provides %d\n", me->get_set_width(), wedgewidth);
  	      if(me->row_pos == 16 || ((float)wedgewidth != me->get_set_width())) // we need to adjust the justification wedges
  	      {
  	        int nf, nc;

            // TODO: we need to check to make sure we don't try to open the mould too wide.

            werror("needs adjustment: have %d, need %.1f!\n", wedgewidth, me->get_set_width());
  	        // first, we should calculate what difference we need, in units of set.
  	        float needed_units = me->get_set_width() - wedgewidth;
 
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
  			      col_pos = "D" + col_pos;
  			    }

  			    // 3. unit adding + unit shift
  			    else if(config->unit_adding && config->unit_shift && me->row_pos > 1 && (me->get_set_width() == (config->unit_adding + s->get(me->row_pos - 1))))
  			    {
  			      row_pos = (me->row_pos - 1);
  			      col_pos = "D" + col_pos;

              buf+=sprintf("0075 ");			
  			    }
  			// 4. underpinning
          
  			// 5. letterspacing via justification wedge (currently the only technique in use here) 
  	        // then, figure out what that adjustment is in terms of 0075 and 0005
				    else
  	        {  	            
//werror("needed units: %d, max_ls_adjustment: %d\n", needed_units, max_ls_adjustment);
  	          if(needed_units > max_ls_adjustment || abs(needed_units) > max_reduction_units)
  	          {
  	            int unit_shift_diff = (me->get_set_width() - s->get(me->row_pos - 1) );
//werror("unit_shift_diff: %d\n", unit_shift_diff);
  	            if(config->unit_shift && me->row_pos > 1 && unit_shift_diff <= max_ls_adjustment && abs(unit_shift_diff) <= max_reduction_units)
  	            {
//werror("yeah!\n");
  	              row_pos = (me->row_pos - 1);
      			      col_pos = "D" + col_pos;
      			      needed_units = me->get_set_width() - s->get(me->row_pos - 1);
  	            }
  	          }
  	          
  	          mixed err = catch([nc, nf] = calculate_wordspacing_code(needed_units));
  	          
  	          if(err && this_combined_space)
  	          {
  	            werror("needed units (w/combined space): %O\n", needed_units + calc_justspace(0, linelength));
                [nc, nf] = calculate_wordspacing_code(needed_units + calc_justspace(0, linelength));
              }
              else if(err)
              {
                throw(err);
              }
  		        // if it's not what we have now, make the adjustment

   		        if(cf != nf || cc != nc)
  		        {
  		          werror("returning from %O %O to %O %O\n", cf, cc, nf, nc);
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
  	  buf+=sprintf("%s %s %s [%s]\n", (string)row_pos, ((col_pos/"")-({""}))*" ", this_combined_space?"S":"", string_to_utf8(c), /* me->get_set_width() */);
      }
    }
    return buf->get();
  }
	
	class MatWrapper
	{
	  constant _is_matwrapper = 1;
		int|float adjust_space;

		object mat;
		
		static void create(object _mat, int|float _adjust_space)
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
		
		float get_set_width()
		{
			return (float)(adjust_space + mat->get_set_width());
		}
		
		
		static mixed `->(mixed a)
		{
			mixed m = ::`->(a);
			if(m) return m;
			else return mat[a];
		}
		mixed _sprintf(mixed x)
		{
		  return "MatWrapper(" + sprintf("%O", mat) + ")";
		}
	}
