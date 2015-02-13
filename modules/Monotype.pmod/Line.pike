w#charset utf8

//! represents a line in a job.

import Monotype;

object generator;

array elements = ({}); 
object errors = ADT.List();


//! the calculated justification setting for the 0075 wedge
int big;

//! the calculated justification setting for the 0005 wedge
int little;

// should justifying spaces be fixed at the "base width" (1 or 2 units less than the js row width)?
int js_are_fixed = 0;
  
  int finalized;
  
  int line_number;
	int line_on_page;
	int col_number;
	
	int combined_space;
//	float calculated_justifying_space = 0.0;
		
	int max_reduction_units;
	int min_space_units;
	int min_little, _min_little;
	int min_big, _min_big;	

//! determines whether a line ends with a galley trip justification code.
int double_justification = 0;
  
int non_spaces;
  
//! set to true if the line has been broken using hyphenation.
int is_broken;
	
//! the calculated size of each justifying space, in units.
float units;
	
//! the number of justifying spaces on this line.
int linespaces; 
	
//! the current number of units set on this line.
float linelength; 
	
//! the total length of the line in units of set.
float lineunits; 
	
//! the set width of the current face/wedge.	
float setwidth;
	
object m, s; // matcase and stopbar objects
mapping config;
	
int max_ls_adjustment = 2;

int cc, cf, c, f; // the current justification wedge settings

ADT.Stack cjc = ADT.Stack();  

  void set_fixed_js(int x)
  {
    if(x)
    {
      js_are_fixed = 1;
      min_little = 1;
      min_big = 1;
    }
    else
    {
      js_are_fixed = 0;
      min_little = _min_little;
      min_big = _min_big;
    }
  }	
  
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
	  col_number = line->col_number;
	  foreach(line->elements; int i; object e)
	    add(e);
	}
	
	static void create(object _m, object _s, mapping _config, object _g)
	{
    config = _config;
		m = _m;
		s = _s;
		generator = _g;
		_min_little = config->min_little||1;
		_min_big = config->min_big||1;
		min_little = _min_little;
		min_big = _min_big;
		
		setwidth = config->setwidth;
		lineunits = (float)config->lineunits;		
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

//! remove a sort from the line; recalculate the justification
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

  if(linespaces && !js_are_fixed)
  {
	// algorithm from page 14
	justspace = (((float)(lineunits)-get_line_length(mylinelength))/linespaces); // in units of set.
  }
//  werror("%f = (%O - %O) / %d\n", justspace, lineunits, get_line_length(mylinelength), linespaces);

  return justspace;
}

class PosFinder
{
  float current_pos = 0.0;

//! calculate the position that each sort /ends/.
//! 
//! @returns an array containing floats or arrays (for sub-lines) indicating
//!   the unit position that the given element occupies.
array calculate_positions(Line line)
{
  array elements = line->elements;
  array pos = allocate(sizeof(elements));
  ADT.List errs = ADT.List();

  float spacewidth; 
  spacewidth = line->calc_justspace(0);

  foreach(elements; int x; mixed elem)
  {
    if(Program.implements(object_program(elem), Line))
    {
      pos[x] = calculate_positions(elem);
    }
    else if(elem->is_real_js)
    {
      current_pos += spacewidth;
    }
    else
    {
      object mat = elem->get_mat(errs);
      if(mat)
      {
        current_pos+=(mat->get_set_width() + elem->space_adjust);      
        pos[x] = current_pos;
      }
    }
  }

  return pos;
}

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

//! calculate the length (in units of set) of items placed in the line.
//! this calculation takes into account any consideration for hanging 
//! punctuation.
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
    if(setwidth > 12.0 && units < -1.0)
      throw(Error.Generic("Unable to reduce width more than 1 unit when set width is greater than 12.\n"));

    int steps = (int)round((0.0007685 * setwidth * units) / 0.0005);
    steps += 53; // 53 is 3/8 code.
    // TODO: check to see if we are opening too wide for the mould.
    array x = ({steps/15, steps%15});
    if(x[1] == 0)
    {
      x[0]--;
      x[1]=15;
    }

    if((x[0] > 15 || x[0] < 1) || (x[1] > 15 || x[1] < 1)) 
      throw(Error.Generic(sprintf("Cannot adjust width by %.1f units; justification code would be %d/%d\n", units, x[0], x[1])));

    return x;
  }

  // add a sort to the current line
  void add(Sort|RealJS|Line activator, int|void atbeginning, int|void stealth)
  {
    object mat;

//werror("Line.add(%O, %O) => %f, %O\n", activator, atbeginning, linelength, min_space_units);
// justifying space
//werror("line length was: %O ", linelength);
    if(Program.implements(object_program(activator), Line))
    {
      if(!activator->can_justify())
        throw(Error.Generic("Unable to add an unjustifyable column to a line.\n"));
      if(activator->lineunits > (lineunits - linelength))
        throw(Error.Generic(sprintf("Unable to fit column on line: have %O units on %O unit line, want to add %O more.\n", lineunits, linelength, activator->lineunits)));
      else
        elements += ({activator});
  	    if(!stealth)
          linelength += activator->lineunits;
        activator->double_justification = 1;
    }
    else if(activator->is_real_js)
    {
      if(atbeginning)
      {
        elements = ({activator}) + elements;
      }
      else
      {
        elements += ({activator});		
      }
      if(!stealth)
        linelength += (min_space_units);
      linespaces ++;
    if(!stealth)
      [big, little] = calculate_justification();
      return;
    }
    else if(mat = activator->get_mat(errors))
    {
//	    werror("have mat: %O width %O, adjust %O\n", mat, mat->get_set_width(), activator->space_adjust);
      if(!stealth)
        linelength+=(mat->get_set_width() + activator->space_adjust);
// 	  	 werror("activator: %O\n", activator);
      if(atbeginning)
      {
        elements = ({activator}) + elements;
      }
      else
      {
        elements += ({activator});		
      }    
    }
    else
    {
      werror("No mat!\n");
    }
    
  //  werror("is now: %O\n", linelength);
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
    if(overset) werror("overset, no need to calc.\n");
    overset = overset || (linespaces && ((mbig*15)+mlittle)<((min_big*15)+min_little));
    if(overset)
    {
//      werror("overset: # %d => line length: %O, units in line: %.1f, to add: %.1f, linespaces: %d, just: %d/%d min: %d/%d\n", line_number, lineunits,  get_line_length(mylinelength), (float)mylinelength, linespaces, mbig, mlittle, min_big, min_little);
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
	  	return((!js_are_fixed && linespaces && ((big <= 15) && (big > 0))  && ((little <= 15) && (little > 0)))
	  	  || (((float)lineunits - (float)linelength) <= 1.0));
	}
	
	array render_line(int|void explode)
	{
	//  errors = ADT.List();
	  array x = ({});
	  foreach(elements;;mixed e)
	  {
	    mixed matrix;
	    
	    if(Program.implements(object_program(e), Line))
	    {
	      if(explode)
	      {
	        array z = e->render_line(1);
	        x += z ;
        }
	      else
	      {
  	      x += ({e});      
	      }
	    }
	    else if(e->is_real_js)
	    {
	      //we must clone the realjs object, otherwise the width calculation will be shared among all js on this line.
	    //  werror("units: %O\n", units);
	      object e2 = object_program(e)(e->matrix);
	      if(combined_space)
	      {
	        e2->is_combined_space = 1;
  	      e2->calculated_width = units;
//	        werror("combinedspace width: %O\n", units);
        }
        else
        {
	        e2->is_combined_space = 0;
  	      e2->calculated_width = min_space_units + units;
//          werror("space width: %O\n", min_space_units + units);
        }
	      x += ({e2});
	    }
	    else if(matrix = e->get_mat(errors))
	    {
//	      werror(string_to_utf8(sprintf("matrix: %O\n", matrix)));
	      x += ({MatWrapper(matrix, e->space_adjust)});
	    }
	    else
	    {
	      werror(string_to_utf8(sprintf("skipping %O/%O\n", e, matrix)));
	    }
	  }
	  
    return x;
	}
	
	string generate_line()
	{
	  String.Buffer buf = String.Buffer();
	  int my_double_justification = 0;
	  this_combined_space = 0;
	  // a little nomenclature here: c == coarse (0075) f == fine (0005), 
    //   cc == current coarse setting, cf == current fine setting
  	  f = little;
  	  c = big;
  	  cf = f;
  	  cc = c;

  	  write("\n");
  	  
  	  // if the last element on the line is a Line object, make _it_ a single justification and we
  	  // can skip the justification code ourselves. we should also force a justification reset, should
  	  // that be needed once we're done with the current chunk.
  	  if(elements && sizeof(elements) && Program.implements(object_program(elements[-1]), Line))
  	  {
  	    cf = 0, cc = 0;
  	    elements[-1]->double_justification = 0;
  	  }
      else
      {  	  
    	  if(double_justification)
          buf->add(sprintf("%s %d\n", generator->fine_code, f));
  	    else
          buf->add(sprintf("%s %s %d\n", generator->fine_code, generator->coarse_code, f));
    
        buf->add(sprintf("%s %d\n", generator->coarse_code, c));
      }
      
      array rendered_line_elements = reverse(render_line());
      foreach(rendered_line_elements; int element_number; object|string me)
      {
        // do we need to add combined space to the last letter of a word?
        if(Program.implements(object_program(me), Line))
        {
          buf->add(me->generate_line());
          continue;
        }
	        if(combined_space && (sizeof(rendered_line_elements) > element_number + 2) 
             && rendered_line_elements[element_number + 1]->is_real_js) 
          this_combined_space = 1;

        add_code(me, buf);
      }
    return buf->get();
  }
  
      int this_combined_space = 0;
	
	// add a code to the ribbon.
	void add_code(object me, object buf, int|void raw)
	{
	      string row_pos = me->row_pos;
        string col_pos = me->col_pos;
        string ch = me->character;

    	  if(me->is_fs || me->is_js)
          ch = " ";
//          werror(string_to_utf8(sprintf("add_code(%O, %O)\n", me, raw)));

        if(!raw)
        {
          
            if(this_combined_space && combined_space)
            {
              if(cf != f || cc != c)
      	      {
      		      werror("resetting justification wedges: %O %O.\n", f, c);
      		      buf->add(sprintf("%s %d\n", generator->fine_code, f));
      		      buf->add(sprintf("%s %d\n", generator->coarse_code, c));
      			    cf = f;
      			    cc = c;
      	      }
            }
            if(me->is_real_js && combined_space)
            {
              return;
            }
            else if(me->is_real_js)
            {
              // if we've previously changed the justification wedges in order to
              // correct a sort width, we need to put things back.
      	      if(cf != f || cc != c)
      	      {
      		      werror("resetting justification wedges: %O %O.\n", f, c);
      		      buf->add(sprintf("%s %d\n", generator->fine_code, f));
      		      buf->add(sprintf("%s %d\n", generator->coarse_code, c));
      			    cf = f;
      			    cc = c;
      	      }
      	      if(config->enable_pneumatic_quads)
                buf->add(sprintf("S %s %d [ ]\n", generator->pneumatic_quad_code, me->matrix->row_pos));
      	      else
                buf->add(sprintf("S %d %s [ ]\n", me->matrix->row_pos, me->matrix->col_pos));
              werror("_");
              return;
            }
            else 
      	    {
     // 	      werror("not a space(%O, %O)\n", me, raw);
              
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

//      	        werror("want %f, wedge provides %f\n", me->get_set_width(), (float)wedgewidth);
      	      if(me->row_pos == 16 || ((float)wedgewidth != me->get_set_width())) // we need to adjust the justification wedges
      	      {
      	        int nf, nc;

                // TODO: we need to check to make sure we don't try to open the mould too wide.

                werror("needs adjustment: have %d, need %.1f!\n", wedgewidth, me->get_set_width());
      	        // first, we should calculate what difference we need, in units of set.
      	        float needed_units = me->get_set_width() - wedgewidth;

                // at this point, we'd select the appropriate mechanism for handling the difference
                // presumably, we'd use the following techniques, were they available to us:

                // 4. underpinning
                object highspace;
                
                werror("need: %O %O\n", (int)needed_units, generator->highspaces);
          			if(needed_units > 0.0 && (highspace = generator->highspaces[(int)needed_units]))
          			{
          			  werror("underpin!\n");
          			  add_code(highspace, buf, 1);
          			  add_code(me, buf, 1);
          			  return;
          			}

                // 1. unit adding
      			    if(config->unit_adding && config->unit_adding == needed_units)
      			    {
                  buf->add(sprintf("0075 "));
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

                  buf->add(sprintf("0075 "));
                
      			    }

      			// 5. letterspacing via justification wedge (currently the only technique in use here) 
      	        // then, figure out what that adjustment is in terms of 0075 and 0005
                else
      	        {
  	              float max;
                  float want = me->get_set_width() * config->setwidth * 0.0007685;
                  if(config->mould >=12) max = 0.170;
                  else max = 0.160; 
              
                  werror("Sort width check: wanted = %f, max allowed = %f inches.\n", want, max);
                  if(want > max) errors->append(sprintf("Requested sort wider than mould would allow: %f > %f inches.\n", want, max));
   	            
    //werror("needed units: %d, max_ls_adjustment: %d\n", needed_units, max_ls_adjustment);
      	          if(needed_units > max_ls_adjustment || abs(needed_units) > max_reduction_units)
      	          {
      	            if(config->unit_shift && me->row_pos > 1)
                    {
                      int unit_shift_diff = (me->get_set_width() - s->get(me->row_pos - 1) );
                      if(unit_shift_diff <= max_ls_adjustment && abs(unit_shift_diff) <= max_reduction_units)
       	              {
      	                row_pos = (me->row_pos - 1);
          			      col_pos = "D" + col_pos;
          			      needed_units = me->get_set_width() - s->get(me->row_pos - 1);
      	              }
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
                    buf->add(sprintf("%s %d\n", generator->fine_code, nf));
      	            buf->add(sprintf("%s %d\n", generator->coarse_code, nc));
                    cf = nf;
      		          cc = nc;
      	          }

      	          buf->add("S ");
      	       }
      	    }
          }
          
 //           werror(string_to_utf8(ch||""));
            
    	  }
    	  if(raw && config->unit_shift)
        {
          col_pos = replace(col_pos, "D", "EF");
        }
        
        // if it's a low space and we have the pneumatic attachment, activate it here.
        if(config->enable_pneumatic_quads && (me->is_fs || me->is_js))
          buf->add(sprintf("%s %s %s [%s]\n", generator->pneumatic_quad_code, (string)row_pos, this_combined_space?"S":"", string_to_utf8(ch||"")));
        else  
          buf->add(sprintf("%s %s %s [%s]\n", (string)row_pos, ((col_pos/"")-({""}))*" ", this_combined_space?"S":"", string_to_utf8(ch||""), /* me->get_set_width() */));

	      if(this_combined_space) this_combined_space = 0;
   
    }
	

