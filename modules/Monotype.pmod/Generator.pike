import Monotype;

// some modes we find useful
constant MODE_JUSTIFY = 0;
constant MODE_LEFT = 1;
constant MODE_RIGHT = 2;
constant MODE_CENTER = 3;

constant dicts = (["en": "hyph_en_US.dic"]);

object hyphenator;

Line current_line;

mapping config;

int interactive = 0;

int numline;

array lines = ({});

array ligatures = ({});
array ligature_replacements_from = ({});
array ligature_replacements_to = ({});

//! the matcase and stopbar objects
object m;
object s;

int modifier = 0;

int isitalics = 0;
int issmallcaps = 0;
int isbold = 0;

int space_adjust = 0;

int line_mode = MODE_JUSTIFY;

string last = "";
array data_to_set = ({});


/*
  setwidth
  linelengthp
  matcase
  stopbar
  mould
*/
void create(mapping settings)
{	

	werror("Monotype.Generator(%O)\n", settings);
  int lineunits = (int)(18 * (1/(settings->setwidth/12.0)) * settings->linelengthp);
werror ("line should be %d units.\n",lineunits);
  m = settings->matcase;
  s = settings->stopbar;

  config = settings;
  config->lineunits = lineunits;
  
  foreach(m->get_ligatures();; object lig)
  {
     ligatures += ({ ({lig->style||"R", lig->activator}) });	
  }

  foreach(ligatures;;array lig)
  {
	werror("lig:%O\n", lig);
    if(!ligature_replacements_to[lig[0]])
      ligature_replacements_to[lig[0]] = ({});
    if(!ligature_replacements_from[lig[0]])
      ligature_replacements_from[lig[0]] = ({});
    ligature_replacements_from[lig[0]] += ({ lig[1], "<A" + lig[1] + ">" });
    ligature_replacements_to[lig[0]] += (({ "<A" + lig[1] + ">" }) * 2 ); 
  }
/*
  ligature_replacements_from = ligatures + map(ligatures, lambda(array a){return "<A" + a[1] + ">";});
  ligature_replacements_to = map(ligatures, lambda(string a){return "<A" + a + ">";}) * 2;
*/

#if constant(Public.Tools.Language.Hyphenate)
  // TODO: make this selectable.
  string lang = "en";
  hyphenator = Public.Tools.Language.Hyphenate.Hyphenate(combine_path(config->dict_dir, dicts[lang]));
#endif
}

void parse(string input)
{
  string s = utf8_to_string(input);

  object parser = Parser.HTML();
  mapping extra = ([]);
  parser->_set_tag_callback(i_parse_tags);
  parser->_set_data_callback(i_parse_data);
  parser->set_extra(extra);


  // feed the data to the parser and have it do its thing.
  parser->finish(s);
}

// TODO: make this method re-entrant.
array lig_syl = ({});
mixed break_ligatures(string syl)
{
  lig_syl = ({});
  object parser = Parser.HTML();
  parser->_set_tag_callback(syl_parse_tags);
  parser->_set_data_callback(syl_parse_data);
  parser->finish(syl);
	
  return lig_syl;
}

mixed syl_parse_data(object parser, string data, mapping extra)
{
	lig_syl += data/"";
}

mixed syl_parse_tags(object parser, string data, mapping extra)
{
	if(Regexp.SimpleRegexp("<[A].*>")->match(data))
	{
		lig_syl += ({(data[2..sizeof(data)-2])});
	}
}

mixed i_parse_data(object parser, string data, mapping extra)
{
    // data_to_set is our setting buffer. when we arrive here, there may be things in it already,
    // such as ligatures and the like. we add whatever data this method was passed.

	// TODO: at the end of the document, we should verify that the setting buffer is empty.
	// possible situations where that might happen include ending the job with a ligature
	// where this callback wouldn't be called.

    string mod = "R";
    if(isitalics) mod = "I";
    else if (issmallcaps) mod = "S";
    else if (isbold) mod = "B";

    string xdata = replace(data, ({"\r", "\t"}), ({" ", " "}));
    string dts = replace(xdata, ligature_replacements_from[mod], ligature_replacements_to[mod] );

	if(dts !=  xdata) return dts;

    foreach(xdata/"\n";; data)
    {
  //    data = ((data / " ") - ({""})) * " ";
//werror("Ligatures: %O, %O", ligatures, map(ligatures, lambda(string a){return "<A" + a + ">";}));

      data_to_set += data/"";
    }

// note that we don't automatically process the buffer when we receive data, as there may be specifically added ligatures
// that won't appear as part of the current word but are logically part of it (which would affect hyphenation, in particular). 
// instead, we keep adding to the buffer until a code that wouldn't appear in the middle of a word arrives. that includes
// things like quads and line endings.
// 
// TODO: we currently also include changes in alphabet here, such as when we transition from roman to italics. that would prevent
// situations where, for example, we italicize part of a word from participating in hyphenation. does this occur often enough 
// to be of concern?
  //  process_setting_buffer();
}

int process_setting_buffer(int|void exact)
{
	int lastjs = 0;
	
	if(!current_line)
	  current_line = make_new_line();
//werror("data_to_set: %O\n", data_to_set);
 
  	  for(int i = 0; i<sizeof(data_to_set) ;i++)
	  {
	   if(data_to_set[i] == " ")
	     if(current_line->elements && sizeof(current_line->elements) && current_line->elements[-1]->is_real_js) 
	       continue;
	  	 else
  	       lastjs = i;
	//werror(" %O", data_to_set[i]);
	   current_line->add(data_to_set[i], create_modifier(), space_adjust);
	
	   if(current_line->is_overset()) // back up to before the last space.
	   {
		  for(int j = i; j >= lastjs; j--)
		  {
			object x = current_line->remove();
//			 werror("removing a character: %O, %O \n", x?(x->activator?x->activator:"JS"):"", ((x && x->get_set_width)?x->get_set_width():0));
		  }
		  if(exact) return 1;
		  if(line_mode)
		  {
			quad_out();
		  }

		  i = lastjs||-1; // if we backed up to the beginning of the setting buffer, that is, there isn't
							// a justifying space in it, we need to back up one more so that we're starting
							// back at the beginning of the buffer, rather than at the js, which we'd skip
							// once we start the next iteration of this loop.

		  // TODO: we probably want to attempt hyphenation when as soon as a word won't fit, not just when we can't justify using a whole word.
		  // if we can't justify, having removed the last word, see if hyphenating will help, regardless if we hyphenated the last line.		
		  if(1 && numline && (!lines[-1]->is_broken || !current_line->can_justify())) 
				  {	
//			werror("trying to hyphenate, justification is %d.\n", current_line->can_justify());
			int bs = search(data_to_set, " ", i+1);
			if(bs!=-1)
			{
				string word = data_to_set[i+1..(bs-1)]*"";
				werror("attempting to hyphenate word %O from %O to %O\n", word, i, bs);
				array wp = hyphenate_word(word);
				werror("word parts are %O\n", wp * ", ");
				if(sizeof(wp)>1)
				{
					array new_data_to_set = data_to_set;
					int new_i = i;
					int new_lastjs = lastjs;
					int fp;
					
					// TODO: we need to reapply ligatures
					for(fp = sizeof(wp)-2; fp >=0; fp--)
					{
						string syl = (" "+(wp[0..fp] * "") + "-");
  					  data_to_set = syl/"";
					//	if(syl != replace(syl, ligature_replacements_from, ligature_replacements_to))
						{
							// we have a ligature in this word part. it must be applied.
					//		data_to_set = break_ligatures(syl);
						}
					werror("seeing if %O will fit...", syl);
					  int res = process_setting_buffer(1);
					  if(!res)
					  {
						werror("yes!\n");
						// it fit!
						if(sizeof(wp)>=fp)
						  data_to_set = (wp[fp+1..] * "" / "") + new_data_to_set[bs..];
//						werror("data to set is %O\n", data_to_set * "");
						i = -1;
						current_line->is_broken = 1;
						break;
					  }
					
					  else // take it all off the line and try again.
					  {
						werror("nope.\n");
					  }

					  if(fp == 0 && !current_line->can_justify()) // we got to the last syllable and it won't fit. we must have a crazy syllable!
						error(sprintf("unable to fit syllable %O on line. unable to justify.\n", wp[0]));
					  else if(fp == 0)
					  {
						data_to_set = ((word)/"") + new_data_to_set[bs..];
						i = -1;
//						werror("data to set is %O\n", data_to_set * "");
					  }
                    }						

				}
			}
		  } 
//		werror("newline, i is %d\n", lastjs);
		  new_line();
	   }
	}
	
	data_to_set = ({});
	return 0;
}

// TODO: this is just aweful. we need to come up with something a little more robust.
	mixed i_parse_tags(object parser, string data, mapping extra)
{

	if(data == "<i>")
	{
		process_setting_buffer();
		isitalics ++;
	}
	if(data == "</i>")
	{
		process_setting_buffer();
		isitalics --;
		if(isitalics < 0) isitalics = 0;
	}
	if(data == "<b>")
	{
		process_setting_buffer();
		process_setting_buffer();
		isbold ++;
	}
	if(data == "</b>")
	{
		process_setting_buffer();
		isbold --;
		if(isbold < 0) isbold = 0;
	}
    if(data == "<sc>")
    {
	   process_setting_buffer();
       issmallcaps ++;
    }
    if(data == "</sc>")
    {
	  process_setting_buffer();
      issmallcaps --;
      if(issmallcaps < 0) issmallcaps = 0;
    }
	if(data == "<left>")
	{
		process_setting_buffer();
		line_mode = MODE_LEFT;
	}
	if(data == "<center>")
	{
		process_setting_buffer();
		line_mode = MODE_CENTER;
	}
	if(data == "<right>")
	{
		process_setting_buffer();
		line_mode = MODE_RIGHT;
	}
	if(data == "<justify>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	else if(data == "<qo>")
	{
	  process_setting_buffer();
		
	  quad_out();
	  new_line();
    }
	else if(data == "<p>")
	{
	  process_setting_buffer();	
	  if(!current_line->can_justify())
        quad_out();
	  new_line();
    }
    else if(Regexp.SimpleRegexp("<[sS][0-9]*>")->match(data))
	{
		process_setting_buffer();
		current_line->add("SPACE_" + data[2..sizeof(data)-2]);
		if(current_line->is_overset())
		{
			current_line->errors += ({"Fixed space (%d unit) won't fit on line... dropping.\n"});
		}
	}
	// letterspacing
	else if(Regexp.SimpleRegexp("<[Ll][0-9]*>")->match(data))
	{
		process_setting_buffer();
		space_adjust = (int)(data[2..sizeof(data)-2]);
	}
	// end letterspacing
	else if(Regexp.SimpleRegexp("</[Ll][0-9]*>")->match(data))
	{
		process_setting_buffer();
		space_adjust = 0;
	}
	else if(Regexp.SimpleRegexp("<[A].*>")->match(data))
	{
		data_to_set+= ({(data[2..sizeof(data)-2])});
/*		if(is_overset())
		{
			lineerrors+=({"Item (%d unit) won't fit on line... dropping.\n"});
		}
		*/
	}
    
}

// TODO: hyphenation seems to barf on wide characters.
array hyphenate_word(string word)
{
#if constant(Public.Tools.Language.Hyphenate)
  word = hyphenator->hyphenate(word);
#endif /* have Public.Tools.Language.Hyphenate */
	
	array wp = word/"-";
	return wp;
}

Line make_new_line()
{
	Line l;
	
	l = Line(m, s, config);
	
	return l;
}

int create_modifier()
{
	int modifier;
	
	if(isitalics) modifier|=MODIFIER_ITALICS;
	if(issmallcaps) modifier|=MODIFIER_SMALLCAPS;

  return modifier;

}
// fill out the line according to the justification method (left/right/etc)
void quad_out()
{
  int left = current_line->lineunits - current_line->linelength;
//  werror("* have %d units left on line.\n", left);

  if(line_mode == MODE_LEFT || line_mode == MODE_JUSTIFY)
  {
	low_quad_out(left);
  }
  else if(line_mode == MODE_RIGHT)
  {
    low_quad_out(left, 1);	
  }
  else if(line_mode == MODE_CENTER)
  {
     int l,r;
     l = left/2;
     r = (left/2) + (left %2);
	 low_quad_out(r);
	 low_quad_out(l, 1);
  }
}

void low_quad_out(int amount, int|void atbeginning)
{
	  array toadd = ({});

	toadd = Monotype.findspace()->simple_find_space(amount, m->spaces);
//	werror("spaces: %O, %O\n", amount, toadd);
	if(!toadd)
  	  toadd = simple_find_space(amount, m->spaces);
      toadd = sort(toadd);
	//  calculate_justification();
	//  werror("to quad out %d, we need the following: %O\n", total, toadd);  
	  foreach(toadd;;int i)
	  {
	    current_line->add("SPACE_" + i, 0, 0, atbeginning);	
	  }
}

// this an inferior quad-out mechanism. we currently favor
// the algorithm in findspace.pike. left here for historical
// completeness.
array simple_find_space(int amount, mapping spaces)
{
	int left = amount;
	int total = left;

	array toadd = ({});

  foreach(reverse(indices(spaces)); int i; int space)
  {
   while(left > space)
   {
		toadd += ({space});
		left -= space;
   }	
  }

 return toadd;
}

// actually generates the ribbon file from an array of lines of sorts.
// line justifications should already be calculated and provided with each 
// line, however, each sort is checked to make sure its requested width is
// the same as the width of the wedge in the same position. if it's not, 
// we can use various methods (currently consisting only of using the 
// space justification wedges) to "nudge" character to the right width, 
// ensuring justification and world peace.
string generate_ribbon()
{  
	int f,c;
	werror("Spaces in matcase: [ %{%d %}]\n", indices(m->spaces));
    werror("*** writing %d lines to the ribbon\n", sizeof(lines));
    String.Buffer buf = String.Buffer();
	
	buf+=sprintf("name: %s\n", config->jobname); 
	buf+=sprintf("face: %s\n", config->matcase->name);
	buf+=sprintf("set: %.2f\n", config->setwidth);
	buf+=sprintf("wedge: %s\n", config->stopbar->name);
	buf+=sprintf("mould: %d\n", config->mould);
	buf+=sprintf("linelength: %.2f\n", config->linelengthp);
	buf+=sprintf("\n");
	
	foreach(reverse(lines);; object current_line)
        {
          // a little nomenclature here: c == coarse (0075) f == fine (0005), 
          //   cc == current coarse setting, cf == current fine setting
	  int cc, cf; // the current justification wedge settings
	  f = current_line->little;
	  c = current_line->big;
	  cf = f;
	  cc = c;
	  write("\n");
          buf+=sprintf("0005 0075 %d\n", f);
          buf+=sprintf("0075 %d\n", c);

          foreach(reverse(current_line->elements);; object me)
          {
	    int needs_adjustment;
            if(me->is_real_js)
            {
              // if we've previously changed the justification wedges in order to
              // correct a sort width, we need to put things back.
	      if(cf != f || cc != c)
	      {
		werror("resetting justification wedges.\n");
		      buf+=sprintf("0005 %d\n", f);
		      buf+=sprintf("0075 %d\n", c);
			  cf = f;
			  cc = c;
	      }
              buf+=sprintf("S %d %s [ ]\n", me->matrix->row_pos, me->matrix->col_pos);
              werror("_");
            }
            else 
	    {
//			werror("ME: %O", mkmapping(indices(me), values(me)));
	      int wedgewidth = s->get(me->row_pos);
	
	      //werror("want %d, wedge provides %d\n", mat->get_set_width(), wedgewidth);
	      if(wedgewidth != me->get_set_width()) // we need to adjust the justification wedges
	      {
	        int nf, nc;
		werror("needs adjustment: have %d, need %d!\n", wedgewidth, me->get_set_width());
		needs_adjustment = 1;
	        // first, we should calculate what difference we need, in units of set.
	        int neededunits = me->get_set_width() - wedgewidth;
			 
			// at this point, we'd select the appropriate mechanism for handling the difference
			// presumably, we'd use the following techniques, were they available to us:
			// 1. unit adding
			// 2. unit shift
			// 3. underpinning
			// 4. letterspacing via justification wedge (currently the only technique in use here) 
	        // then, figure out what that adjustment is in terms of 0075 and 0005
                [nc, nf] = current_line->calculate_wordspacing_code(neededunits);
		// if it's not what we have now, make the adjustment
		if(cf != nf || cc != nc)
		{

              buf+=sprintf("0005 %d\n", nf);
	          buf+=sprintf("0075 %d\n", nc);
                  cf = nf;
		  cc = nc;
	        }
	      }
			
	      if(needs_adjustment)
	        buf+=sprintf("S ");
          string c = me->character;
	      if(me->is_fs || me->is_js)
	        c = " ";
			//werror("ME: %O\n", me->mat);
          werror(string_to_utf8(c));
	      buf+=sprintf("%d %s [%s]\n", me->row_pos, me->col_pos, string_to_utf8(c));
	   }
       }
    }  

  buf+=sprintf("0075 0005 1\n"); // stop the pump, eject the line.

  return (string)buf;
}

// add the current line to the job, if it's justifyable.
object new_line()
{
  if(!current_line->linespaces && current_line->linelength != current_line->lineunits) throw(Error.Generic(sprintf("Off-length line: expected %d, got %d\n", current_line->lineunits, current_line->linelength)));
  else if(current_line->linespaces && !current_line->can_justify()) throw(Error.Generic(sprintf("Bad Justification: %d %d\n", current_line->big, current_line->little)));
  
  numline++;
  lines += ({current_line});
  current_line = make_new_line();
}
