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
       "fr_FR": "hyph_es_ES.dic",
       "fr_FR": "hyph_it_IT.dic",
		]);

object hyphenator;
mapping hyphenation_rules = ([]);

Line current_line;

mapping config;

int interactive = 0;

int numline;
int pagenumber;
int linesonpage;

object JustifyingSpace;

mapping spaces = ([]);

array(Line) lines = ({});

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
int canHyphenate = 1;

string d_code = "D";
string fine_code = "0005";
string coarse_code = "0075";

float space_adjust = 0.0;
int indent_adjust = 0;

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

  werror ("line should be %d units.\n", lineunits);

  config = settings;
  config->lineunits = lineunits;

  if(settings->matcase)
    set_matcase(settings->matcase);
  if(settings->stopbar)
    set_stopbar(settings->stopbar);
  
  // set up the code substitutions for unit adding
  if(config->unit_adding)
  {
	  fine_code = "N K J";
	  coarse_code = "N K";
  }

  if(config->unit_shift)
  {
      d_code = "E F";
  }  
    
  load_hyphenator();
}

void set_matcase(Monotype.MatCaseLayout mca)
{
  m = mca;
  
  load_ligatures(m);

  object js = m->elements["JS"];
	// houston, we have a problem!
  if(!js) error("No Justifying Space in MCA!\n");
  if(s)
    load_spaces(m);

  JustifyingSpace = RealJS(js);
}

void set_stopbar(Monotype.Stopbar stopbar)
{
  s = stopbar;
  if(m)
    load_spaces(m);
}

void set_hyphenation_rules(string rules)
{
  hyphenation_rules = ([]);
  foreach(rules/"\n";;string rule)
  {
    rule = String.trim_all_whites(rule);
    if(!strlen(rule))
      continue;
    rule = lower_case(rule);
    hyphenation_rules[rule - "-"] = rule;
  }
  
  werror("hyphenation rules: %O\n", hyphenation_rules);
}

protected void load_hyphenator()
{
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

protected void load_spaces(object m)
{
  foreach(m->spaces;;object mat)
    spaces[s->get((mat->row_pos<16?mat->row_pos:15))] = mat;  
  
  if(config->unit_shift)
  {
    foreach(m->spaces;;object mat)
    {
      object ns = mat->clone();
      float new_width = (float)s->get(mat->row_pos-1 || mat->row_pos);
      ns->set_width = new_width;
      spaces[(int)new_width] = ns;
    }
  }
  
  werror("SPACES: %O\n", spaces);
}

protected void load_ligatures(object m)
{
    foreach(m->get_ligatures();; object lig)
    {
      ligatures += ({ ({lig->style||"R", lig->activator}) });	
    }

    foreach(ligatures;;array lig)
    {
//    	werror("lig:%O\n", lig);
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

//  werror("ligs from:%O\n", ligature_replacements_from);
//  werror("ligs to:%O\n", ligature_replacements_to);
}

protected array prepare_data(array data, void|StyledSort template)
{
  array out = allocate(sizeof(data));
  foreach(data; int i; mixed d)
  {
    if(d == " ")
      out[i] = JustifyingSpace;
    else
      out[i] = create_styled_sort(d, space_adjust, template);
  }
  
  return out;
}

//! @param input
//!  a native pike widestring (not utf8 encoded, etc)
void parse(string input)
{
  object parser = Parser.HTML();
  mapping extra = ([]);
  parser->_set_tag_callback(i_parse_tags);
  parser->_set_data_callback(i_parse_data);
  parser->set_extra(extra);

  // feed the data to the parser and have it do its thing.
  parser->finish(input);

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

      data_to_set += prepare_data(data/"");
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

void insert_header(int|void newpara)
{
	pagenumber++;
    linesonpage = 0;
	string header_code;
	if(pagenumber%2) header_code = oheader_code;
	else header_code = eheader_code;
	
	make_new_line();
    current_line->line_on_page = linesonpage;
	
	if(!in_do_header && sizeof(header_code))
	{
		in_do_header = 1;
		current_line->errors->append("* New Page Begins -");
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
	make_new_line(newpara);
}

void insert_footer()
{
	string footer_code;
	if(pagenumber%2) footer_code = ofooter_code;
	else footer_code = efooter_code;
	
	make_new_line();
	
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
	object tightline;
	object phline;
	int tightpos;
	if(!current_line)
	{
	  // if we get here, and there's no line present, it's the first line of the job, thus, by default, a new paragraph.
	  insert_header(1);
	}
 
  for(int i = 0; i<sizeof(data_to_set) ;i++)
	{
	  tightline = 0;
	  tightpos = 0;
	  if(data_to_set[i]->is_real_js)
    {
      lastjs = i;
      // we don't want to allow duplicated justifying spaces, nor justifying spaces first on the line.
	    if(current_line->elements && (sizeof(current_line->elements) && current_line->elements[-1]->is_real_js) || !current_line->non_spaces || !sizeof(current_line->elements)) 
		  {
	      continue;
		  }
    }
    else
      current_line->non_spaces++;
      
	  current_line->add(data_to_set[i]);

    // if permitted, prepare a tight line for possible use later.
	  if(current_line->is_overset() && config->enable_combined_space)
	  {   
      // first, let's see if removing 1 unit from each justifying space will work.
     	object tl = Line(m, s, config + (["combined_space": 1]), this);
	   	tl->re_set_line(current_line);
	     	
      int j = i;

	   	if(lastjs != i) // we're not at the end of a word, here, folks.
      {
 	      while(sizeof(data_to_set)>++j && data_to_set[j] != JustifyingSpace)
 	      {
          tl->add(data_to_set[i]);
        } 
      }
 	     
	   	if(!tl->is_overset()) // did the word fit using combined spaces?
    	{
    	  werror("tight line fit!\n");
     	  tl->line_number = current_line->line_number;
     	  tl->line_on_page = current_line->line_on_page;
    	  tightline = tl;	 
    	  tightpos = j;  
	     }
	     else
	     {
	       werror("tight line didn't fit.\n");
	     }
    }
     
	  if(current_line->is_overset()) // back up to before the last space.
	  {
	    werror("word didn't fit, justification is %d/%d\n", current_line->big, current_line->little);
      object x;

		  int can_try_hyphenation = 0;
		  if(!current_line->hyphenation_disabled())
		  {
  		  if(numline && sizeof(lines) && (!lines[-1]->is_broken || !current_line->can_justify()))
	  	    can_try_hyphenation = 1;
		    else if(config->unnatural_word_breaks)
		      can_try_hyphenation = 1; 
      }

      do
		  {
			  x = current_line->remove();
		  }
      while(x && x!= JustifyingSpace);

	    werror("removed word, justification is %d/%d\n", current_line->big, current_line->little);
		  if(exact) return 1;

      // prepare a clone of the line, so that we can jump back easily.

	    phline = Line(m, s, config, this);
	   	phline->re_set_line(current_line);
     	
		  if(line_mode)
		  {
		    quad_out();
		  }

		  i = lastjs||-1; 
		  // if we backed up to the beginning of the setting buffer, that is, there isn't
			// a justifying space in it, we need to back up one more so that we're starting
			// back at the beginning of the buffer, rather than at the js, which we'd skip
			// once we start the next iteration of this loop.

		  // if we can't justify, having removed the last word, see if hyphenating will help, regardless if we hyphenated the last line.		
      
		  if(can_try_hyphenation)
			{	
			  int prehyphenated;
      	
			  int bs = search(data_to_set, JustifyingSpace, i+1);
			  if(bs!=-1)
			  {
			    array wordsorts = data_to_set[i+1..(bs-1)];
				  string word = (wordsorts->character)*"";
				  werror("attempting to hyphenate word %O from %O to %O\n", word, i, bs);

				  array word_parts;
				  if(search(word, "-") != -1)
				  {
				    word_parts = word / "-";
				    prehyphenated = 1;
				  }
				  else
				  {
  				  word_parts = hyphenate_word(word);				    
				  }
				  werror("word parts are %O\n", word_parts * ", ");

				  // if there are no hyphenation options, we're stuck.
				  if(sizeof(word_parts)<=1)
				  {
			      if(!current_line->can_justify() && tightline) // if we can't fit the line by breaking, see if there's a tightly justified line that will work.
  			    {
  			      werror("can't justify with regular word spaces, but we can with combined spaces, so let's do that.\n");
  			      current_line = tightline;
  			      i = tightpos;
  			      new_line();
  			      continue;
  			    }			  
				  }

				  else // there are syllables in this word.
				  {
					  array new_data_to_set = data_to_set;
					  int new_i = i;
					  int new_lastjs = lastjs;
					  int final_portion; // the last segment of the word being hyphenated

            
					  // for each word part, attempt to add the word, starting with the maximum parts.
					  for(final_portion = sizeof(word_parts)-2; final_portion >=0; final_portion--)
					  {
					    // first, we need to get the sorts that make up this syllable. it's possible that the syllable
					    // contains ligatures, so we might not be able to fully 
					    string portion = (word_parts[0..final_portion] * "");
					    string carry = "";
					    int currentsort = 0;
					    array sortsinsyllable = ({});
			  		  int simple_break;
				  	  object brokenlig;
					    string syl;
					  
					    werror("portion: %O\n", portion);
					  
  					  foreach(portion/""; int x; string act)
	  				  {
		  			    carry += word[x..x];
		  			    werror("carry: %O, sort: %O\n", carry, wordsorts[currentsort]->character);
			  		    if(wordsorts[currentsort]->character == carry)
				  	    {
					        sortsinsyllable += ({wordsorts[currentsort]});
					        carry = "";
  					      currentsort++;
					      }
  					  }
					  
					    werror("sortsinsyllable: %O\n", sortsinsyllable);
					    werror("sortsinsyllable: %O\n", sortsinsyllable->character);

					    if(lower_case(sortsinsyllable->character * "") == portion)
					    {
					      // we have the whole shebang. no need to mess with re-ligaturing.
					      data_to_set = ({JustifyingSpace});
					      data_to_set += sortsinsyllable;
					      simple_break = 1;
					    }
					    else
					    {
					      werror("sorts in syllable = %O, portion = %O\n", sortsinsyllable->character, portion);
					      // we don't have the whole portion. most likely, the end of the portion breaks a ligature.
					      // so, we look at the sort in wordsorts after the last in the sortsinsyllable.
					      data_to_set = ({JustifyingSpace});
					      data_to_set += sortsinsyllable;

  					    brokenlig = wordsorts[sizeof(sortsinsyllable)];
	  				  
	  				    werror("broken ligature: %O\n", brokenlig->character);
	  				    
	  				    // syl is the part of the syllable containing a hanging ligature.
  					    syl = (portion[sizeof(sortsinsyllable->character * "")..]);
  					    //werror("syl: %O\n", syl);
  					    string modifier = "R";
  					    
  					    if(sizeof(sortsinsyllable))
  					       modifier = sortsinsyllable[-1]->get_modifier();
  					       
		  				  string lsyl = replace(syl, ligature_replacements_from[modifier]||({}), ligature_replacements_to[modifier]||({}));
 
	  					  if(syl != lsyl)
  						  {
		  					  // we have a ligature in this word part. it must be applied.
			  				  data_to_set += prepare_data(break_ligatures(lsyl), brokenlig);
				  		  }
					  	  else data_to_set +=  prepare_data(syl/"", brokenlig);
					    }

              // add a hyphen in the style of the last sort added.
	  					if(!(config->unnatural_word_breaks && config->hyphenate_no_hyphen))
	  					{
	  					  object template;
	  					  int i = -1;
	  					  do
	  					  {
	  					    template = current_line->elements[i];
	  					    werror("template: %O\n", template);
	  					    i--;
	  					  } while(template->is_real_js);
	  					  
		  				  data_to_set += prepare_data(({"-"}), template);
	  				  }
			 	    
			  		  werror("seeing if %O will fit... %O", portion, data_to_set);
				  	  int res = process_setting_buffer(1);
					    if(!res)
					    {
						    werror("yes!\n");
						    // it fit! now we must put the rest of the word in the setting buffer.
						    if(sizeof(word_parts)>=final_portion)
						    {	
						      if(simple_break)
						      {
						       // werror("simple.\n");  
    						    if(prehyphenated)
      						    data_to_set += wordsorts[sizeof(sortsinsyllable) + final_portion+1..];
                    else
  						        data_to_set = wordsorts[sizeof(sortsinsyllable)..];
						        
						      }
						      else
						      {
						        // it gets more complex here, as we have to put the second half of the broken ligature in first.
						        data_to_set = prepare_data((brokenlig->character[sizeof(syl)..])/"", brokenlig) + wordsorts[sizeof(sortsinsyllable)+1 ..];
						      
						        // TODO
						        // there is a chance that we may have to rescan for ligatures if the trailing portion of the broken ligature
						        // combines with the first sort(s) of the next word part to form a ligature itself.
						      }						    
						    }
						    
						    data_to_set += prepare_data(({" "}));
  					    data_to_set += new_data_to_set[bs+1..];
						    i = -1;
						    current_line->is_broken = 1;
						    break;
					    }
					
					    else // take it all off the line and try again.
					    {
						    werror("nope.\n");
					    }

  					  if(final_portion == 0 && !current_line->can_justify()) // we got to the last syllable and it won't fit. we must have a crazy syllable!
	  					{
		  				  if(tightline) // if we can't fit the line by breaking, see if there's a tightly justified line that will work.
			  			  {
				  		    werror("can't justify with regular word spaces, but we can with combined spaces, so let's do that.\n");
					  	    current_line = tightline;
						      i = tightpos;
						      new_line();
						      continue;
						    }
                else
  						    error(sprintf("unable to fit syllable %O on line. unable to justify.\n", word_parts[0]));
					    }
					    else if(final_portion == 0)
					    {
					      werror("sadness.\n");
					      array toadd = ({});
					      if(sizeof(new_data_to_set) > (bs+1))
					        toadd = new_data_to_set[bs+1..];

							  string lsyl = replace(word, ligature_replacements_from[sortsinsyllable[-1]->get_modifier()]||({}), ligature_replacements_to[sortsinsyllable[-1]->get_modifier()]||({}));
							  if(word != lsyl)
							  {
								  // we have a ligature in this word part. it must be applied.
								  data_to_set = prepare_data((({" "}) + break_ligatures(lsyl)) + ({" "}), wordsorts[-1]) + toadd;
							  }
  							else data_to_set = prepare_data(((" " + word)/"") + ({" "}), wordsorts[-1])  + toadd;
 
  						  i = -1;
	  				  }
            }						
			  	}
			  }
		  } 
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

  switch(lcdata)
  {
    case "<footer>":
		  in_even = 1;
		  in_odd = 1;
		  in_footer = 1;
		  return 0;
    
    case "</footer>":
      in_footer = 0;
		  return 0;

    case "<header>":
      in_even = 1;
      in_odd = 1;
      in_header = 1;
      return 0;

    case "</header>":
		  in_header = 0;
		  return 0;
      
    case "<ofooter>":
      in_even = 0;
      in_odd = 1;
      in_footer = 1;
	    return 0;

    case "</ofooter>":
		  in_footer = 0;
		  return 0;
    
    case "<oheader>":
		  in_even = 0;
		  in_odd = 1;
		  in_header = 1;
		  return 0;

    case "</oheader>":
      in_header = 0;
      return 0;

    case "<efooter>":
		  in_even = 1;
      in_odd = 0;
      in_footer = 1;
      return 0;

    case "</efooter>":
		  in_footer = 0;
		  return 0;

    case "<eheader>":
		  in_even = 1;
		  in_odd = 0;
		  in_header = 1;
		  return 0;

    case "</eheader>":
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
//		process_setting_buffer();
		isitalics ++;
	}
	if(lcdata == "</i>")
	{
//		process_setting_buffer();
		isitalics --;
		if(isitalics < 0) isitalics = 0;
	}
	if(lcdata == "<b>")
	{
	//	process_setting_buffer();
	//	process_setting_buffer();
		isbold ++;
	}
	if(lcdata == "</b>")
	{
//		process_setting_buffer();
		isbold --;
		if(isbold < 0) isbold = 0;
	}
    if(lcdata == "<sc>")
    {
//	   process_setting_buffer();
       issmallcaps ++;
    }
    if(lcdata == "</sc>")
    {
//	  process_setting_buffer();
      issmallcaps --;
      if(issmallcaps < 0) issmallcaps = 0;
    }

  if(lcdata == "<nohyphenation>")
  {
    werror("disABLING HYPHENATION\n");
    canHyphenate = 0;  
  }

  if(lcdata == "</nohyphenation>")
  {
    canHyphenate = 1;  
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
	else if(lcdata == "<right>")
	{
		process_setting_buffer();
		line_mode = MODE_RIGHT;
	}
	else if(lcdata == "</right>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	else if(lcdata == "<justify>")
	{
		process_setting_buffer();
		line_mode = MODE_JUSTIFY;
	}
	else if(lcdata == "</justify>")
	{
		process_setting_buffer();
		line_mode = MODE_LEFT;
	}
	else if(lcdata == "<qo>")
	{
	  process_setting_buffer();
		
		new_paragraph(1);
    }
	else if(lcdata == "<p>")
	{
	  process_setting_buffer();	
	  new_paragraph();
    }
	// insert fixed spaces
    else if(Regexp.SimpleRegexp("<[sS][0-9]*>")->match(data))
	{
		process_setting_buffer();
		int toadd = (int)(data[2..sizeof(data)-2]);
    float added = low_quad_out((float)toadd);
		if((float)added != (float)toadd)
		{
			current_line->errors->append(sprintf("Fixed space (want %f units, got %f) won't fit on line... dropping.\n", (float)toadd, added));
		}
	}
	// indent
	else if(Regexp.SimpleRegexp("<indent[\\-0-9]*>")->match(lcdata))
	{
	  indent_adjust = (int)(data[7..sizeof(data)-2]);
		process_setting_buffer();
	}
	// end letterspacing
	else if(Regexp.SimpleRegexp("</indent[\\-0-9]*>")->match(lcdata))
	{
		indent_adjust = 0;
		process_setting_buffer();
	}

	// letterspacing
	else if(Regexp.SimpleRegexp("<[Ll].*>")->match(data))
	{
//		process_setting_buffer();
		string sa = (data[2..sizeof(data)-2]);
		int w, f;
		sscanf(sa, "%d.%d", w, f);
		werror("sa: %s, w: %d, f: %d\n", sa, w, f);
		if(!(<0, 5>)[f])
		  throw(Error.Generic("Invalid adjustment " + sa + ". Only whole and half unit adjustments allowed.\n"));
		sscanf(sa, "%f", space_adjust);	
	}
	// end letterspacing
	else if(Regexp.SimpleRegexp("</[Ll].*>")->match(data))
	{
//		process_setting_buffer();
		space_adjust = 0.0;
	}
	// insert an activator
	else if(Regexp.SimpleRegexp("<[Aa].*>")->match(data))
	{
    if(data[2..sizeof(data)-2] == "JS")
      data_to_set += ({ JustifyingSpace });
    else
      data_to_set+= ({(create_styled_sort(data[2..sizeof(data)-2], space_adjust))});
	}
	else if(has_prefix(lcdata, "<setpagenumber "))
	{
		int matches, pn;
		matches = sscanf(lcdata, "<setpagenumber %d%*s>", pn);
		if(matches)
		  pagenumber = (pn-1); // we always increment before going into header, so account for that here.
		else
			current_line->errors->append("Failed to set page number, unable to extract desired number.\n");
			
	}
	else if(lcdata == "<pagenumber>")
	{
	   		  data_to_set += prepare_data(((string)pagenumber)/"");
	}
	else if(lcdata == "<romanpagenumber>")
	{
	   		  data_to_set += prepare_data((String.int2roman(pagenumber))/"");
	}
	else if(lcdata == "<lowercaseromanpagenumber>")
	{
	   		  data_to_set += prepare_data(lower_case(String.int2roman(pagenumber))/"");
	}
    else if(lcdata == "<pagebreak>")
	{
	   		 break_page();
	}	
}

// TODO: hyphenation seems to barf on wide characters.
array hyphenate_word(string word)
{
  // defer to custom hyphenations, first.
  if(hyphenation_rules)
  {
    object regex = Regexp.PCRE.Widestring("\\w");
    string nword = lower_case(word);
    nword = filter(nword, lambda(int c){return regex->match(String.int2char(c));}); 
    if(hyphenation_rules[nword])
      return hyphenation_rules[nword]/"-";
   }
     
#if constant(Public.Tools.Language.Hyphenate)
  if(hyphenator)
  {
    word = hyphenator->hyphenate(word);
werror("hyphenator present\n");
  }
#endif /* have Public.Tools.Language.Hyphenate */
	
    array word_parts = word/"-";
werror("config->unnatural_word_breaks: %O\n", config->unnatural_word_breaks)	;

    if(!(sizeof(word_parts) > 1) && config->unnatural_word_breaks)
    {
werror("splitting unnaturally.\n");
	word_parts = word/"";
    }
	
    return word_parts;
}

void new_paragraph(int|void quad)
{
  if(!quad && current_line->can_justify()) /* do not quad out */ ; 
  else
    quad_out();
  new_line(1);  
}

void make_new_line(int|void newpara)
{
  current_line = low_make_new_line();
  
  if(indent_adjust)
	{
  	float toadd = (float)indent_adjust;
  	if(newpara && toadd > 0)
  	{
  	  werror("indent %O.\n", indent_adjust);
    	if(low_quad_out(toadd) != toadd)
      {
  	    current_line->errors->append(sprintf("Fixed space (%.1f unit) won't fit on line... dropping.\n", toadd));
      }	
    }
    else if(!newpara && toadd < 0)
    {
  	  werror("hanging indent %O.\n", indent_adjust);
      toadd = abs(toadd);
      
    	if(low_quad_out(toadd) != toadd)
      {
  	    current_line->errors->append(sprintf("Fixed space (%.1f unit) won't fit on line... dropping.\n", toadd));
      }	      
    }
	}	
}

Line low_make_new_line()
{
	Line l;	
	
	l = Line(m, s, config, this);
	l->line_number = ++numline;
	linesonpage++;
	l->line_on_page = linesonpage;
	return l;
}

object create_styled_sort(string sort, float adjust, void|StyledSort template)
{
  if(template)
    return template->clone(sort);
  else
    return StyledSort(sort, m, config, isitalics, isbold, issmallcaps, adjust, !canHyphenate);
}

// fill out the line according to the justification method (left/right/etc)
void quad_out()
{
  werror("quad_out()\n");
  float left = current_line->lineunits - current_line->linelength;
  werror("* have %.1f units left on line.\n", left);

  while(!current_line->can_add(left))
  {
    werror("onoe!\n");
    left --;
//    Tools.throw(Error.Generic, "unable to add %d units because it would cause the line to be overset.\n", left);
  }

  werror("* %.1f units can be added to give acceptably sized justifying spaces.\n", left);

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
     float l,r;
     l = left/2;
     r = (left/2) + (left %2);
	 low_quad_out(r);
	 low_quad_out(l, 1);
  }
}

float low_quad_out(float amount, int|void atbeginning)
{
//  werror("low_quad_out(%f, %d)\n", amount, atbeginning);
  
  array toadd = ({});
  int ix;
  toadd = Monotype.findspace()->simple_find_space((int)floor(amount), spaces);
  if(!toadd || !sizeof(toadd))
    toadd = Monotype.IterativeSpaceFinder()->findspaces((int)floor(amount), spaces);
  if(!toadd || !sizeof(toadd))
    toadd = simple_find_space((int)floor(amount), spaces);

  toadd = reverse(toadd);

  foreach(toadd;int z;int i)
  {
    ix+=i;
//    werror("adding(%O, %d)\n", i, atbeginning);
    
    current_line->add(Sort(spaces[i]), atbeginning, 0);	
	if(current_line->is_overset())
	{
      werror("overset. added %.2f, at %d\n", current_line->linelength, ix);
      current_line->remove();ix-=i;
      if(current_line->can_justify())
        break;
      else
      {
        werror("what's smaller than %d?\n", i);
        array whatsleft = ({});
        // generate an array of available spaces smaller than the one that didn't fit.
        foreach(spaces; mixed u ;)
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
            current_line->add(Sort(spaces[toadd]), atbeginning, 0);	
            cj = current_line->can_justify();
          }
          while(!cj && !current_line->is_overset());
					
          if(current_line->is_overset())
          {
			while(z)
			{
              current_line->remove();
			  z--;
			}
			return 0;
          }
        }
      }
    }
  }

  werror("asked to add %.1f units of space; added %d.\n", amount, ix);
  return (float)ix;
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

void break_page(int|void newpara)
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

	if(config->unit_shift)
          buf+=sprintf("unit_shift: enabled\n");

	buf+=sprintf("\n");
	
	foreach(reverse(lines);; object current_line)
  {
    buf += current_line->generate_line();
  }  

  buf+=sprintf("%s %s 1\n", coarse_code, fine_code); // stop the pump, eject the line.

  return (string)buf;
}

// add the current line to the job, if it's justifyable.
void new_line(int|void newpara)
{
  if(!current_line->linespaces && (float)current_line->linelength != (float)current_line->lineunits)
  {
      throw(Error.Generic(sprintf("Off-length line without justifying spaces: need %d units to justify, line has %.1f units. Consider adding a justifying space to line - %s\n", 
		current_line->lineunits, current_line->linelength, (string)current_line)));
  }
  else if(current_line->linespaces && !current_line->can_justify()) 
    throw(Error.Generic(sprintf("Unable to justify line; %f length with %f units, %d spaces, justification code would be: %d/%d, text on line is %s\n", (float)current_line->linelength, (float)current_line->lineunits, current_line->linespaces, current_line->big, current_line->little, (string)current_line)));

// if this is the first line and we've opted to make the first line long 
//  (to kick the caster off,) add an extra space at the beginning.
  if(config->trip_at_end && numline == 1)
  {
	string activator = "";
	array aspaces = indices(spaces);
	int spacesize;
	aspaces = sort(aspaces);

	if(sizeof(aspaces))
	  spacesize = aspaces[-1];
	if(spacesize)
	{
		// add at least 18 units of space to the line.
		for(int i = spacesize; i <= 18; i+=spacesize)
	 		current_line->add(Sort(spaces[spacesize]), 1, 1);
	}
	else
	{
		throw(Error.Generic("No spaces in matcase, unable to produce a caster-trip line.\n"));
	}
		
  }
  lines += ({current_line});

  if(config->page_length && !(linesonpage%config->page_length))
  {
  	break_page(newpara);
  }
  else
    make_new_line(newpara);
}