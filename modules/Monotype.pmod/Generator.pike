import Monotype;

// some modes we find useful
constant MODE_JUSTIFY = 0;
constant MODE_LEFT = 1;
constant MODE_RIGHT = 2;
constant MODE_CENTER = 3;

constant dicts = (["en_US": "hyph_en_US.dic",
		   "nl_NL": "hyph_nl_NL.dic",
		   "de_DE": "hyph_de_DE.dic",
		   "de_CH": "hyph_de_CH.dic",
                   "fr_FR": "hyph_fr_FR.dic",

		]);

object hyphenator;

Line current_line;

mapping config;

int interactive = 0;

int numline;
int pagenumber;
int linesonpage;

array lines = ({});

array ligatures = ({});
mapping ligature_replacements_from = ([]);
mapping ligature_replacements_to = ([]);

string eheader_code = "";
string efooter_code = "";
string oheader_code = "";
string ofooter_code = "";

//! the matcase and stopbar objects
object m;
object s;

int modifier = 0;

int isitalics = 0;
int issmallcaps = 0;
int isbold = 0;

string fine_code = "0005";
string coarse_code = "0075";

int space_adjust = 0;

int line_mode = MODE_JUSTIFY;

string last = "";
array data_to_set = ({});


/*
  Settings (partial):
    setwidth
    linelengthp
    matcase
    stopbar
    mould
*/
void create(mapping settings)
{	

	werror("Monotype.Generator(%O)\n", settings);
  int lineunits = (int)(18 * (settings->pointsystem||12) * 
			(1/settings->setwidth) * settings->linelengthp);
werror ("line should be %d units.\n",lineunits);
  m = settings->matcase;
  s = settings->stopbar;

  config = settings;
  config->lineunits = lineunits;
  
  // set up the code substitutions for unit adding
  if(config->unit_adding)
  {
	fine_code = "N K J";
	coarse_code = "N K";
  }

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

werror("ligs from:%O\n", ligature_replacements_from);
werror("ligs to:%O\n", ligature_replacements_to);

#if constant(Public.Tools.Language.Hyphenate.Hyphenate)
  string lang = "en";
  if(config->lang) lang = config->lang;
  if(config->hyphenate)
  {
    werror("loading hyphenator " + dicts[lang] + "\n");
    hyphenator = Public.Tools.Language.Hyphenate.Hyphenate(combine_path(config->dict_dir, dicts[lang]));
  }
#else
werror("No hyphentation engine present, functionality will be disabled.\n");
#endif
}

//! @param input
//!  a native pike widestring (not utf8 encoded, etc)
void parse(string input)
{
  string s = input;

  object parser = Parser.HTML();
  mapping extra = ([]);
  parser->_set_tag_callback(i_parse_tags);
  parser->_set_data_callback(i_parse_data);
  parser->set_extra(extra);


  // feed the data to the parser and have it do its thing.
  parser->finish(s);

  // put the footer at the end of the set text if we have one.
  if(config->page_length)
	insert_footer();
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

	if(in_header)
	{
		if(in_even)
		  eheader_code += data;
		if(in_odd)
		  oheader_code += data;
		return 0;
	}
	else if(in_footer)
	{
		if(in_even)
		  efooter_code += data;
		if(in_odd)
		  ofooter_code += data;
		return 0;
	}	

    string mod = "R";
    if(isitalics) mod = "I";
    else if (issmallcaps) mod = "S";
    else if (isbold) mod = "B";

    string xdata = replace(data, ({"\r", "\t"}), ({"\n", " "}));
    string dts = replace(xdata, ligature_replacements_from[mod] || ({}), ligature_replacements_to[mod] || ({}));

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

void insert_header()
{
	pagenumber++;
    linesonpage = 0;
	string header_code;
	if(pagenumber%2) header_code = oheader_code;
	else header_code = eheader_code;
	
	current_line = make_new_line();
    current_line->line_on_page = linesonpage;
	
	if(!in_do_header && sizeof(header_code))
	{
		in_do_header = 1;
		current_line->errors += ({"* New Page Begins -"});
		werror("parsing header: %O\n", header_code);
		array _data_to_set = data_to_set;
		data_to_set = ({});
		object parser = Parser.HTML();
		mapping extra = ([]);
		parser->_set_tag_callback(i_parse_tags);
		parser->_set_data_callback(i_parse_data);
		parser->set_extra(extra);

		// feed the data to the parser and have it do its thing.
		parser->finish(header_code);
		data_to_set = _data_to_set;
		in_do_header = 0;
	}
}

void insert_footer()
{
	string footer_code;
	if(pagenumber%2) footer_code = ofooter_code;
	else footer_code = efooter_code;
	
	current_line = make_new_line();
	
	if(!in_do_footer && sizeof(footer_code))
	{
		in_do_footer = 1;
		werror("parsing footer: %O\n", footer_code);
		array _data_to_set = data_to_set;
		data_to_set = ({});
		object parser = Parser.HTML();
		mapping extra = ([]);
		parser->_set_tag_callback(i_parse_tags);
		parser->_set_data_callback(i_parse_data);
		parser->set_extra(extra);

		// feed the data to the parser and have it do its thing.
		parser->finish(footer_code);
		data_to_set = _data_to_set;
		in_do_footer = 0;
	}
}

int process_setting_buffer(int|void exact)
{
	int lastjs = 0;
	
	if(!current_line)
	{
//	  current_line = make_new_line();
	  insert_header();
	}
// werror("data_to_set: %O\n", data_to_set);
 
  	  for(int i = 0; i<sizeof(data_to_set) ;i++)
	  {
	    if(data_to_set[i] == " ")
        {
          lastjs = i;
	      if(current_line->elements && sizeof(current_line->elements) && current_line->elements[-1]->is_real_js) 
		  {
			werror("continue\n");
	        continue;
		  }
     	}
//	werror("+ %O", data_to_set[i]);
	   current_line->add(data_to_set[i], create_modifier(), space_adjust);
	
	   if(current_line->is_overset()) // back up to before the last space.
	   {
	    werror("word didn't fit, justification is %d/%d\n", current_line->big, current_line->little);
object x;
//		  for(int j = i; j >= lastjs; j--)
// TODO: if the non-fitting word was made up of components from more than one alphabet (roman, italic, etc),
// the word will be removed and placed back on the line using only one alphabet, namely the one containing the 
// last part of the word that fits. That's because we don't associate the alphabet with the text to be placed on
// the line as part of the setting buffer. We should probably change the setting buffer to contain the alphabet
// (and other settings) of the word, instead of relying on a global flag to contain this information. That way,
// we can remove the whole word and hyphenate it while preserving changes in settings within the word.
do
		  {
			x = current_line->remove();
			 werror("removing a character: %O, %O \n", x?(x->activator?x->activator:"JS"):"", ((x && x->get_set_width)?x->get_set_width():0));
		  }
while(x && x->activator);

	    werror("removed word, justification is %d/%d\n", current_line->big, current_line->little);
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
//werror("left to set: %O\n", data_to_set[i..] * "");
		werror("numline: %O, is_broken: %O, can_justify: %O\n", 
                          numline,  1||lines[-1]->is_broken, current_line->can_justify());
		int can_try_hyphenation = 0;
		if(1 && numline && sizeof(lines) && (!lines[-1]->is_broken || !current_line->can_justify()))
		  can_try_hyphenation = 1;
		else if(config->unnatural_word_breaks)
		  can_try_hyphenation = 1; 

		  if(can_try_hyphenation)
				  {	
			werror("trying to hyphenate, justification is %d.\n", current_line->can_justify());
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

					string mod = "R";
				    if(isitalics) mod = "I";
				    else if (issmallcaps) mod = "S";
				    else if (isbold) mod = "B";
					
					// TODO: we need to reapply ligatures
					for(fp = sizeof(wp)-2; fp >=0; fp--)
					{
					    
						string syl = (" "+(wp[0..fp] * "") + ((config->unnatural_word_breaks && config->hyphenate_no_hyphen)?"":"-"));
						string lsyl = replace(syl, ligature_replacements_from[mod]||({}), ligature_replacements_to[mod]||({}));
  			//		    data_to_set = replace(syl/"", ligature_replacements_from[mod] || ({}), ligature_replacements_to[mod] || ({}));
						if(syl != lsyl)
						{
							// we have a ligature in this word part. it must be applied.
							data_to_set = break_ligatures(lsyl);
						}
						else data_to_set = syl/"";
						
					werror("seeing if %O will fit...", syl);
					  int res = process_setting_buffer(1);
					  if(!res)
					  {
						werror("yes!\n");
						// it fit!
						if(sizeof(wp)>=fp)
						{	
							string lsyl = replace(wp[fp+1..]*"", ligature_replacements_from[mod]||({}), ligature_replacements_to[mod]||({}));
			  			//		    data_to_set = replace(syl/"", ligature_replacements_from[mod] || ({}), ligature_replacements_to[mod] || ({}));
							if((wp[fp+1..]*"") != lsyl)
							{
								// we have a ligature in this word part. it must be applied.
								data_to_set = break_ligatures(lsyl) + new_data_to_set[bs..];
							}
							else 
						  		data_to_set = (wp[fp+1..] * "" / "") + new_data_to_set[bs..];
						}
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
							string lsyl = replace(word, ligature_replacements_from[mod]||({}), ligature_replacements_to[mod]||({}));
			  			//		    data_to_set = replace(syl/"", ligature_replacements_from[mod] || ({}), ligature_replacements_to[mod] || ({}));
							if(word != lsyl)
							{
								// we have a ligature in this word part. it must be applied.
								data_to_set = break_ligatures(lsyl) + new_data_to_set[bs..];
							}
							else data_to_set = ((word)/"") + new_data_to_set[bs..];

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

int in_do_footer;
int in_do_header;
int in_footer;
int in_header;
int in_even;
int in_odd;

// TODO: this is just aweful. we need to come up with something a little more robust.
	mixed i_parse_tags(object parser, string data, mapping extra)
{
    string lcdata = lower_case(data);

	if(lcdata == "<footer>")
	{
		in_even = 1;
		in_odd = 1;
		in_footer = 1;
		return 0;
	}

	if(lcdata == "</footer>")
	{
		in_footer = 0;
		return 0;
	}

	if(lcdata == "<header>")
	{
		in_even = 1;
		in_odd = 1;
		in_header = 1;
		return 0;
	}

	if(lcdata == "</header>")
	{
		in_header = 0;
		return 0;
	}

	if(lcdata == "<ofooter>")
	{
		in_even = 0;
		in_odd = 1;
		in_footer = 1;
		return 0;
	}

	if(lcdata == "</ofooter>")
	{
		in_footer = 0;
		return 0;
	}

	if(lcdata == "<oheader>")
	{
		in_even = 0;
		in_odd = 1;
		in_header = 1;
		return 0;
	}

	if(lcdata == "</oheader>")
	{
		in_header = 0;
		return 0;
	}

	if(lcdata == "<efooter>")
	{
		in_even = 1;
		in_odd = 0;
		in_footer = 1;
		return 0;
	}

	if(lcdata == "</efooter>")
	{
		in_footer = 0;
		return 0;
	}

	if(lcdata == "<eheader>")
	{
		in_even = 1;
		in_odd = 0;
		in_header = 1;
		return 0;
	}

	if(lcdata == "</eheader>")
	{
		in_header = 0;
		return 0;
	}


    if(in_footer)
    {
		if(in_even)
		  efooter_code += data;
		if(in_odd)
		  ofooter_code += data;
		return 0;
    }

    if(in_header)
    {
		if(in_even)
  		  eheader_code += data;
		if(in_odd)
		  oheader_code += data;
		return 0;
    }
	
	if(lcdata == "<i>")
	{
		process_setting_buffer();
		isitalics ++;
	}
	if(lcdata == "</i>")
	{
		process_setting_buffer();
		isitalics --;
		if(isitalics < 0) isitalics = 0;
	}
	if(lcdata == "<b>")
	{
	//	process_setting_buffer();
		process_setting_buffer();
		isbold ++;
	}
	if(lcdata == "</b>")
	{
		process_setting_buffer();
		isbold --;
		if(isbold < 0) isbold = 0;
	}
    if(lcdata == "<sc>")
    {
	   process_setting_buffer();
       issmallcaps ++;
    }
    if(lcdata == "</sc>")
    {
	  process_setting_buffer();
      issmallcaps --;
      if(issmallcaps < 0) issmallcaps = 0;
    }
	if(lcdata == "<left>")
	{
		process_setting_buffer();
		line_mode = MODE_LEFT;
	}
	if(lcdata == "</left>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	if(lcdata == "<center>")
	{
		process_setting_buffer();
		line_mode = MODE_CENTER;
	}
	if(lcdata == "</center>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	if(lcdata == "<right>")
	{
		process_setting_buffer();
		line_mode = MODE_RIGHT;
	}
	if(lcdata == "</right>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	if(lcdata == "<justify>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	if(lcdata == "</justify>")
	{
		process_setting_buffer();
		line_mode = MODE_LEFT;
	}
	else if(lcdata == "<qo>")
	{
	  process_setting_buffer();
		
	  quad_out();
	
	  new_line();
    }
	else if(lcdata == "<p>")
	{
	  process_setting_buffer();	
	  if(!current_line->can_justify())
        quad_out();
	  new_line();
    }
	// insert fixed spaces
    else if(Regexp.SimpleRegexp("<[sS][0-9]*>")->match(data))
	{
		process_setting_buffer();
		low_quad_out((int)(data[2..sizeof(data)-2]));
//		current_line->add("SPACE_" + data[2..sizeof(data)-2]);
		if(current_line->is_overset())
		{
			current_line->errors += ({"Fixed space (%d unit) won't fit on line... dropping.\n"});
		}
	}
	// letterspacing
	else if(Regexp.SimpleRegexp("<[Ll][\\-0-9]*>")->match(data))
	{
		process_setting_buffer();
		space_adjust = (int)(data[2..sizeof(data)-2]);
	}
	// end letterspacing
	else if(Regexp.SimpleRegexp("</[Ll][\\-0-9]*>")->match(data))
	{
		process_setting_buffer();
		space_adjust = 0;
	}
	// insert an activator
	else if(Regexp.SimpleRegexp("<[Aa].*>")->match(data))
	{
                if(data[2..sizeof(data)-2] == "JS")
                  data_to_set += ({ " " });
                else
   		  data_to_set+= ({(data[2..sizeof(data)-2])});
/*		if(is_overset())
		{
			lineerrors+=({"Item (%d unit) won't fit on line... dropping.\n"});
		}
		*/
	}
	else if(has_prefix(lcdata, "<setpagenumber "))
	{
		int matches, pn;
		matches = sscanf(lcdata, "<setpagenumber %d%*s>", pn);
		if(matches)
		  pagenumber = (pn-1); // we always increment before going into header, so account for that here.
		else
			current_line->errors += ({"Failed to set page number, unable to extract desired number.\n"});
			
	}
	else if(lcdata == "<pagenumber>")
	{
	   		  data_to_set += ((string)pagenumber)/"";
	}
	else if(lcdata == "<romanpagenumber>")
	{
	   		  data_to_set += (String.int2roman(pagenumber))/"";
	}
	else if(lcdata == "<lowercaseromanpagenumber>")
	{
	   		  data_to_set += lower_case(String.int2roman(pagenumber))/"";
	}
    else if(lcdata == "<pagebreak>")
	{
	   		 break_page();
	}
	
}

// TODO: hyphenation seems to barf on wide characters.
array hyphenate_word(string word)
{
#if constant(Public.Tools.Language.Hyphenate)
  if(hyphenator)
  {
    word = hyphenator->hyphenate(word);
werror("hyphenator present\n");
  }
#endif /* have Public.Tools.Language.Hyphenate */
	
    array wp = word/"-";
werror("config->unnatural_word_breaks: %O\n", config->unnatural_word_breaks)	;

    if(!(sizeof(wp) > 1) && config->unnatural_word_breaks)
    {
werror("splitting unnaturally.\n");
	wp = word/"";
    }
	
    return wp;
}

Line make_new_line()
{
	Line l;
	
	l = Line(m, s, config);
	l->line_number = ++numline;
	linesonpage++;
	l->line_on_page = linesonpage;
	return l;
}

int create_modifier()
{
	int modifier;
	
	if(isitalics) modifier|=MODIFIER_ITALICS;
	if(isbold) modifier|=MODIFIER_BOLD;
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
//werror("spaces in case: %O\n", m->spaces);
//werror("requested to add %d, on line already: %d\n", amount, current_line->linelength);
int ix;
	toadd = Monotype.findspace()->simple_find_space(amount, m->spaces);
//	werror("jzfindspaces: %O, %O\n", amount, toadd);
	if(!toadd || !sizeof(toadd))
          toadd = Monotype.IterativeSpaceFinder()->findspaces(amount, m->spaces);
//	werror("iterativespaces: %O, %O\n", amount, toadd);
	if(!toadd || !sizeof(toadd))
  	  toadd = simple_find_space(amount, m->spaces);
     // toadd = sort(toadd);
//	werror("spaces: %O, %O\n", amount, toadd);
	//  calculate_justification();
//	  werror("to quad out %d, we need the following: %O\n", amount, toadd);  
toadd = sort(toadd);

	  foreach(toadd;;int i)
	  {
ix+=i;
//	werror("adding %d, at %d\n", i, ix);
	    current_line->add("SPACE_" + i, 0, 0, atbeginning);	
		if(current_line->is_overset())
		{
werror("overset. added %d, at %d\n", current_line->linelength, ix);
			current_line->remove();ix-=i;
			if(current_line->can_justify())
				break;
			else
			{
				werror("what's smaller than %d?\n", i);
				array whatsleft = ({});
				// generate an array of available spaces smaller than the one that didn't fit.
				foreach(m->spaces; mixed u ;)
				{
				   if(u < i)
						whatsleft += ({u});
				}
				whatsleft = reverse(sort(whatsleft));
				
				// ok, the plan is to take each space, starting with the biggest and try to add as many
				// of each as possible without going over.
				foreach(whatsleft;;int toadd)
				{   
				  int cj;
				
					do
					{
ix+=toadd;
			    		current_line->add("SPACE_" + toadd, 0, 0, atbeginning);	
						cj = current_line->can_justify();
					}
					while(!cj && !current_line->is_overset());
					
					if(current_line->is_overset())
{
ix-=toadd;
						current_line->remove();
}
				}
			}
		}
	  }

werror("asked to add %d units of space; added %d.\n", amount, ix);
}

// this an inferior quad-out mechanism. we currently favor
// the algorithm in findspace.pike. left here for historical
// completeness.
array simple_find_space(int amount, mapping spaces)
{
	int left = amount;
	int total = left;

	array toadd = ({});

  if(spaces[9] && spaces[18])
     spaces[27] = 1;

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

void break_page()
{
	insert_footer();		
	insert_header();		
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
	if(config->unit_adding)
  	  buf+=sprintf("unit_adding: %s units\n", (string)config->unit_adding);

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
          buf+=sprintf("%s %s %d\n", fine_code, coarse_code, f);
          buf+=sprintf("%s %d\n", coarse_code, c);

          foreach(reverse(current_line->elements);; object me)
          {
            if(me->is_real_js)
            {
              // if we've previously changed the justification wedges in order to
              // correct a sort width, we need to put things back.
	          if(cf != f || cc != c)
	          {
		werror("resetting justification wedges.\n");
		        buf+=sprintf("%s %d\n", fine_code, f);
		        buf+=sprintf("%s %d\n", coarse_code, c);
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
                [nc, nf] = current_line->calculate_wordspacing_code(needed_units);
		        // if it's not what we have now, make the adjustment

 		        if(cf != nf || cc != nc)
		        {
                  buf+=sprintf("%s %d\n", fine_code, nf);
	              buf+=sprintf("%s %d\n", coarse_code, nc);
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
}  

  buf+=sprintf("%s %s 1\n", coarse_code, fine_code); // stop the pump, eject the line.

  return (string)buf;
}

// add the current line to the job, if it's justifyable.
void new_line(int|void q)
{
	
/*
  if(!q && !current_line->linespaces && current_line->linelength != current_line->lineunits) 
  {
      current_line->remove();
      current_line->add(" ", create_modifier(), space_adjust);
      quad_out();
      new_line(1);           
      return;
  }
  else */if(!current_line->linespaces && current_line->linelength != current_line->lineunits)
  {
      throw(Error.Generic(sprintf("Off-length line without justifying spaces: need %d units to justify, line has %d units. Consider adding a justifying space to line - %s\n", 
		current_line->lineunits, current_line->linelength, (string)current_line)));
  }
  else if(current_line->linespaces && !current_line->can_justify()) 
throw(Error.Generic(sprintf("Unable to justify line; justification code would be: %d/%d, text on line is %s\n", current_line->big, current_line->little, (string)current_line)));

// if this is the first line and we've opted to make the first line long 
//  (to kick the caster off,) add an extra space at the beginning.
  if(config->trip_at_end && numline == 1)
  {
	string activator = "";
	array spaces = indices(m->spaces);
	int spacesize;
	spaces = sort(spaces);

	if(sizeof(spaces))
	  spacesize = spaces[-1];
	if(spacesize)
	{
		// add at least 18 units of space to the line.
		for(int i = spacesize; i <= 18; i+=spacesize)
	 		current_line->add("SPACE_" + spacesize, 0, 0, 1, 1);
	}
	else
	{
		throw(Error.Generic("No spaces in matcase, unable to produce a caster-trip line.\n"));
	}
		
  }
  lines += ({current_line});

  if(config->page_length && !(linesonpage%config->page_length))
  {
	break_page();
  }
  else
    current_line = make_new_line();


}
