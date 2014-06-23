import Fins;
inherit "mono_doccontroller";

int __quiet = 1;


mapping pointsystems = (["12.0":"Anglo-American Pica", "12.84":"Cicero", "12.8":"Old English Pica"]);

void start()
{
  before_filter(app->admin_user_filter);
  after_filter(Fins.Helpers.Filters.Compress());
}

//int __quiet = 1;

public void index(Request id, Response response, Template.View v, mixed ... args)
{
	return;
}

public void generate(Request id, Response response, Template.View v, mixed ... args)
{
  object user = id->misc->session_variables->user;
  
  if(id->variables->load_config)
  {
     mapping c;
     object rc;
     array rv = Fins.Model.find.ribbon_configs((["id": (int)id->variables->config, "User": user]));
     if(sizeof(rv))
       rc = rv[0];
     if(!rc)
       throw(Error.Generic("Unable to find ribbon config for user " + user["username"] + " with id=" + id->variables->config + ".\n"));
     
     c = decode_value(rc["definition"]);
     
     id->variables += c;
     v->add("load_config", 1);
  }

  array mcac = app->get_mcas();
  array mcas = ({});
    
  foreach(mcac;; object c)
  {
    if(c["owner"] == user || c["is_public"])
      mcas += ({ ({ (string)c["id"], c["name"] }) });
  }
  
  array wedgec = app->get_wedges();
  array wedges = wedgec[*]["name"];
   
  werror("config: %O\n", id->variables);
 // werror("wedges: %O\n", wedges);

   //werror("matcases: %O\n", app->get_mcas());
    v->add("mcas", mcas);
    v->add("wedges", wedges);
    v->add("owner", user);
    v->add("configs", Fins.Model.find.ribbon_configs((["User": user])));
    
	return;
}

public void get_wedge_for_mca(Request id, Response response, Template.View v, mixed args)
{
	string w;
	//werror("args: %O\n", args);
	
	object mca = app->load_matcase(args[0]);

    if(!mca) w = "000";

    else w = mca->wedge;
	//werror("wedge: " + w);
	response->set_data(w);
}

public mapping extract_settings(Request id)
{
werror("EXCTRACT_SETTINGS: %O\n", id->variables);
  return ([
		"justification": (int)id->variables->justification,
		"unit_adding": (int)id->variables->unitadding,
		"unit_shift": (int)(id->variables->unit_shift),
		"mould": (int)id->variables->pointsize,
		"pointsystemname": pointsystems[id->variables->pointsystem||"12.0"],
		"pointsystem": (float)id->variables->pointsystem,
		"setwidth": (float)id->variables->set,
		"linelengthp": (float)id->variables->linelength,
		"stopbar": app->load_wedge(id->variables->wedge),
		"matcase": app->load_matcase_by_id(id->variables->mca),
		"jobname": id->variables->jobname,
		"dict_dir": combine_path(app->config->app_dir, "config"),
    "lang": id->variables->lang,
    "hyphenate": (int)id->variables->hyphenate,
		"unnatural_word_breaks": (int)id->variables->unnatural_word_breaks,
		"hyphenate_no_hyphen": (int)id->variables->hyphenate_no_hyphen,
		"trip_at_end": (int)id->variables->trip_at_end,
		"page_length": (int)id->variables->page_length,
		"maximum_quad_units": (int)id->variables->maximum_quad_units,
		"enable_pneumatic_quads": (int)id->variables->enable_pneumatic_quads,
		"enable_combined_space": (int)id->variables->enable_combined_space,
		"min_little": (int)(((id->variables->min_just||"")/"/")[1]), 
		"min_big": (int)(((id->variables->min_just||"")/"/")[0]),
		"hanging_punctuation": (int)id->variables->hanging_punctuation,
		"pad_margins": (int)id->variables->pad_margins,
		"allow_lowercase_smallcaps": (int)id->variables->allow_lowercase_smallcaps,
		"allow_punctuation_substitution": (int)id->variables->allow_punctuation_substitution
		]);
}

public void do_generate(Request id, Response response, Template.View v, mixed ... args)
{
    // the job settings are stored in a mapping stored in the session object when we validate the file.
    // we can then retrieve them in the next step, here.
	id->variables = id->misc->session_variables["job_" + id->variables->job_id];
//werror("job_id is %d\n", (int)id->variables->job_id);
	m_delete(id->misc->session_variables, "job_" + id->variables->job_id);

	mapping settings = extract_settings(id);
	werror("%O\n", settings);	
		string data;
		if(id->variables->input_type=="file") data = /*utf8_to_string*/(id->variables["input-file"]);
		else data = id->variables->input_text;
		// = "Now is the time for all good men to come to the aid of their country. Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go.<qo>";
	
	// skip braindead windows byte order mark.
	if(data[0..2] == "\xEF\xBB\xBF") data = data[3..];

	object g = Monotype.Generator(settings);
	g->set_hyphenation_rules(id->misc->session_variables->user["Preferences"]["hyphenation_rules"]["value"]);
	g->parse(data);

    response->set_data(g->generate_ribbon());
    response->set_header("content-disposition", "attachment; filename=\"" + 
        (id->variables->jobname || "untitled_job") + ".rib\"");	
    response->set_type("application/x-monotype-e-ribbon");
    response->set_charset("utf-8");
    id->misc->session_variables->generator = -1;
    id->misc->session_variables->generator = 0;
}

public void get_line(Request id, Response response, Template.View v, string line)
{
  response->set_data("<html>Codes for line " + ((int)line + 1) + ":<p>\n<pre style=\"font-family: courier, monospace; font-size: 8pt;\">\n" + replace(id->misc->session_variables->generator->lines[(int)(line)]->generate_line(), "\n", "\n") + "</pre><p/> <p/></html>\n");
}

#if constant(Image.TrueType)
public void trick(Request id, Response response, Template.View v, mixed ... args)
{
  
  mixed test_stopbar = Monotype.load_stopbar(combine_path(getcwd(), "../test/wedges", "s5"));
  mixed test_mca = Monotype.load_matcase(combine_path(getcwd(), "../test/matcases", "garamond"));
  mixed dictdir = combine_path(getcwd(), "../test/dicts");
  mapping settings = ([
      "allow_lowercase_smallcaps": 0,
      "allow_punctuation_substitution": 0,
      "enable_combined_space": 1,
      "enable_pneumatic_quads": 0,
      "hyphenate": 1,
      "hyphenate_no_hyphen": 0,
      "jobname": "",
      "justification": 1,
      "lang": "en_US",
      "min_big": 1,
      "min_little": 8,
      "mould": 12,
      "page_length": 42,
      "pointsystem": 12.0,
      "setwidth": 11.0,
      "unit_adding": 0,
      "unit_shift": 0,
      "unnatural_word_breaks": 0,
      "dict_dir": dictdir,
      "matcase": test_mca,
      "stopbar": test_stopbar,
    ]);
    
  
  
   	object g, b;
     Error.Generic err;
   	int max_red = 2;
string job_id = "tricky";
     mixed parse_time;

     parse_time
      = gauge {
     	
     	g = Monotype.ShapeGenerator(settings + (["unnatural_word_breaks": 1]), "Q");
         	g->set_hyphenation_rules(id->misc->session_variables->user["Preferences"]["hyphenation_rules"]["value"]);
        array words = ({});
        int x = 0;
        do{
          int len = random(6);
          string word = "";
          for(int i = 0; i < (len||3); i++)
            word += sprintf("%c", 'a' + random(25) );
          words += ({word});
        }while(x++ < 700);
        string t = words * " ";
          
          
       //   werror("words: %O\n", t);
      
      //return;
   	  err = Error.mkerror(catch(g->parse("<allowtightlines>" + 
   	  /*  "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
   	              "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
   	              "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                   "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                    "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                     "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                      "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                  "Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go."
                  */
                  
            t
            + "<p>")));
   	  id->misc->session_variables->generator = g;
   	  b = String.Buffer();
     };

   	if(err)
   	{
   		b+="<div style=\"clear: left\">\n";
   		b+="An error occurred while validating the ribbon: <p><b>";
   		b+=(err->message());
   		b+="</b><p/>";
   		b+="The ribbon will be displayed up to the point of the error.";
   		b+="<!--\n\n";
   		b+=err->describe();
   		b+="\n\n-->";
   		b+="</div>\n";

   		Tools.Logging.Log.exception("An error occurred.", err);
   	}
   	werror("parse_time: %O\n", parse_time);

    b = render_proof(b, g);
       v->add("job_id", job_id);
       v->add("result", b);

       response->set_charset("utf-8");
  
}
#endif /* Image.TrueType */

public void do_validate(Request id, Response response, Template.View v, mixed ... args)
{
  object user = id->misc->session_variables->user;
  response->set_header("Cache-control", "no-cache");
	if(id->variables->delete_config)
	{
	  object rc;
    array rv = Fins.Model.find.ribbon_configs((["id": (int)id->variables->dconfig, "User": user]));
    if(sizeof(rv))
      rc = rv[0];
    if(!rc)
      throw(Error.Generic("Unable to find ribbon config for user " + user["username"] + " with id=" + id->variables->dconfig + ".\n"));
	  
	  string name = rc["name"];
	  rc->delete();
	  
	  response->flash("msg", "Settings " + name + " deleted.");
	  response->redirect_temp(generate);
	  return;
  }  
  
	else if(id->variables->load_config)
	{
	  object rc;
    array rv = Fins.Model.find.ribbon_configs((["id": (int)id->variables->config, "User": user]));
    if(sizeof(rv))
      rc = rv[0];
    if(!rc)
      throw(Error.Generic("Unable to find ribbon config for user " + user["username"] + " with id=" + id->variables->config + ".\n"));
    
	  response->flash("msg", "Settings loaded from " + rc["name"] + ".");	  
	  response->redirect_temp(generate, ({}), (["load_config": 1, "config": rc["id"]]));
	  return;
	}
	else if(id->variables->save_config)
	{
	  object settings;
	  
	  string name = String.trim_all_whites(id->variables->name || "");
	  if(id->variables->save_name != "") name = id->variables->save_name;
	  
	  if(!name) 
	  { 
	    response->flash("msg", "No template name specified.");
	    response->redirect_temp(generate);  
	  }
	  
    array rv = Fins.Model.find.ribbon_configs((["name": name, "User": user]));
    if(sizeof(rv))
      settings = rv[0]; 
    else
      settings = Keyboard.Objects.Ribbon_config();

//      throw(Error.Generic("Configuration for " + user["username"] + " with name=" + name + " already exists.\n"));
	  
	  mapping s = copy_value(id->variables);
	  m_delete(s, "input-file");
    m_delete(s, "save_config");
    m_delete(s, "load_config");
    m_delete(s, "delete_config");
    m_delete(s, "config");
    m_delete(s, "dconfig");
    m_delete(s, "name");
    
    werror("s: %O\n", s);
    string se = encode_value(s);
    
    settings["name"] = name;
    settings["definition"] = se;
    settings["User"] = user;
    
    if(settings->is_new_object())
      settings->save();
    
	  response->flash("msg", "Settings saved as " + name + ".");
	  response->redirect_temp(generate, ({}), (["load_config": 1, "config": settings["id"] ]));
	  return;
	}
	
	//werror("%O\n", id->variables);
	int job_id = random(9999999);
	id->misc->session_variables["job_" + job_id] = id->variables;
	mapping settings = extract_settings(id);
	
	// we don't need this to be shown in the "soft proof".
  m_delete(settings, "trip_at_end");
  		
	string data;
	if(id->variables->input_type=="file") data = /*utf8_to_string*/(id->variables["input-file"]);
	else data = (id->variables->input_text);

	// skip braindead windows byte order mark.
	if(data && data[0..2] == "\xEF\xBB\xBF") data = data[3..];

	// = "Now is the time for all good men to come to the aid of their country. Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go.<qo>";
	
	object g, b;
  Error.Generic err;

  mixed parse_time;
  
  parse_time
   = gauge {
  	g = Monotype.Generator(settings);
  	g->set_hyphenation_rules(id->misc->session_variables->user["Preferences"]["hyphenation_rules"]["value"]);
	  err = Error.mkerror(catch(g->parse(data)));
	  id->misc->session_variables->generator = g;
	  b = String.Buffer();
  };
 
	if(err)
	{
		b+="<div style=\"clear: left\">\n";
		b+="An error occurred while validating the ribbon: <p><b>";
		b+=(err->message());
		b+="</b><p/>";
		b+="The ribbon will be displayed up to the point of the error.";
		b+="<!--\n\n";
		b+=err->describe();
		b+="\n\n-->";
		b+="</div>\n";

		Tools.Logging.Log.exception("An error occurred.", err);
	}
	werror("parse_time: %O\n", parse_time);

   b = render_proof(b, g);

   v->add("settings", settings);
   v->add("now", Calendar.now());
    v->add("job_id", job_id);
    v->add("result", b);

    response->set_charset("utf-8");
	
//	string s = g->generate_ribbon();
//	response->set_data(b);
	return;
}

String.Buffer render_proof(String.Buffer b, Monotype.Generator g)
{
  	int units;
  	
  	int max_red = 2;  
    if(g->config->setwidth > 12.0)	
  	  max_red = 1;
  	
    if(g->lines && sizeof(g->lines)) units = (int)g->lines[-1]->units;
    else if(g->current_line) units = (int)g->current_line->units;

  	b+="<div style=\"clear: left\">";
  	b+=("<div style=\"position:relative; float:left; width:50px\">Line</div><div style=\"position:relative; float:left; width:" 
  		+ units + "px\">&nbsp;</div><div></div><div>Just Code / Comments</div>");
  	b+=("</div>");

  //	foreach(g->lines + (err?({g->current_line}):({})); int i; mixed line)
    mixed render_time = gauge {
  	foreach(g->lines; int i; mixed line)
  	{
  //	  werror("line: %O\n", line->elements);
  		int mod;
  		int setonline;
  		int last_was_space = 0;
  		int last_set;
  //		b+="<span dojoType=\"dojox.widget.DynamicTooltip\" connectId=\"line_" + i + "\" href=\"" + action_url(get_line, ({(string)i}))+ "\" preventCache=\"true\">nevah seen!</span>";
  		b+="<div style=\"clear: left\" id=\"line_" + i + "\" >";
  		b+=("<div style=\"position:relative; float:left; width:50px\">" + (i+1) 
  			+ "/"  + (sizeof(g->lines) - i)+ "</div>");
  		string tobeadded = "";
  		int tobeaddedwidth = 0;
  		int total_set; 
  		float spill =0.00;

  		foreach(line->render_line(1);int col; mixed e)
  		{
  		 if(e->is_real_js)
  		  {
  			  if(tobeadded != "")
  			  {
  			    b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + tobeaddedwidth + "px\">" + tobeadded + "</div>");
  			    tobeadded = "";
  			    tobeaddedwidth = 0;
  			  }
  			// need some better work on this.
  		float w;
  	      w = e->calculated_width;
  		    setonline+=(int)floor(w);

   		// spill is used to even out the display lines, as we're not able to depict fractional units accurately on the screen.
  		    spill += (e->calculated_width-floor((float)e->calculated_width));
  		    if(spill >= 1.0) { w+=1; spill -=1.0; }

  		total_set += (e->matrix->get_set_width()-max_red);
  		    b += ("<div style=\"position:relative; float:left; background:" + (!e->is_combined_space?"orange":"red") + "; width:" + floor(w) + "px\"> &nbsp; </div>");
    			last_was_space = 1;
  		  }
  		  else if(e->is_fs || e->is_js)
  		  {
  			  if(tobeadded != "")
  			  {
  			    b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + tobeaddedwidth + "px\">" + tobeadded + "</div>");
  			    tobeadded = "";
  			    tobeaddedwidth = 0;
  			  }
  			// need some better work on this.
  		    float w = e->get_set_width();
  		    setonline+=(int)floor(w);
  		    mod++;

       		// spill is used to even out the display lines, as we're not able to depict fractional units accurately on the screen.
      		    spill += (e->get_set_width()-floor((float)e->get_set_width(   )));
      		    if(spill >= 1.0) { w+=1; spill -=1.0; }

  		    if(mod%2)					    
  		      b += ("<div style=\"position:relative; float:left; background:pink; width:" + floor(w) + "px\">&nbsp;</div>");
  		    else
  		      b += ("<div style=\"position:relative; float:left; background:lightpink; width:" + floor(w) + "px\">&nbsp;</div>");
  			  last_was_space = 1;
  		  }
    		  else
   		  {
  			total_set += e->get_set_width();
  			 tobeaddedwidth += e->get_set_width();
  			 setonline+=e->get_set_width();
  			string ch = e->character;

  			  if(e->style == "I")
  			   ch = "<i>" + ch + "</i>";
  			  if(e->style == "B")
  			   ch = "<b>" + ch + "</b>";
  			  if(e->style == "S")
  			   ch = "<font size=\"-1\">" + ch + "</font>";


  			if(e->mat && (float)e->get_set_width() != (float)e->mat->get_set_width())
  			  ch = "<span style=\"text-decoration: overline; color: blue\">" + ch + "</span>";

  			 if(sizeof(e->character) > 1) 
  			  tobeadded += ("<u>" + (ch||" &nbsp; ") + "</u>");
  			 else
    			   tobeadded += (ch||" &nbsp; ");
  		  }

  //		  if((total_set-last_set) <= max_red) werror("%d %d whee!\n", i, col);
  		  last_set = total_set;
          }		

  			if(tobeadded != "")
  			{
  			  b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + (tobeaddedwidth) + "px\">" + tobeadded + "</div>");
  			  tobeadded = "";
  			  tobeaddedwidth = 0;
  			}
  		b+=(" &nbsp; " /* +total_set + " " +(setonline) */ + " &lt;== " + line->big + " " + line->little /*+ " " + line->units*/ + "[" + line->line_on_page + "]");
  		b+=" [<a onClick=\"showCodes(" + i + ", '" + action_url(get_line, ({(string)i})) + "')\">Codes</a>]";

  		if(line->errors && sizeof(line->errors))
  		  b+= (Tools.Array.consolidate((array)line->errors) * ", ");
  		b+=("</div>\n");
  	}
  };
  werror("proof render_time: %O, %O\n", render_time, b);
  return b;
}

public mapping extract_font_settings(Request id)
{
werror("EXCTRACT_FONT_SETTINGS: %O\n", id->variables);
  return ([
		"justification": (int)id->variables->justification,
		"unit_adding": (int)id->variables->unitadding,
		"unit_shift": (int)(id->variables->unit_shift),
		"mould": (int)id->variables->pointsize,
		"pointsystemname": pointsystems[id->variables->pointsystem||"12.0"],
		"pointsystem": (float)id->variables->pointsystem,
		"setwidth": (float)id->variables->set,
                "scheme": id->variables->scheme,
		"linelengthp": (float)id->variables->linelength,
		"stopbar": app->load_wedge(id->variables->wedge),
		"matcase": app->load_matcase_by_id(id->variables->mca),
		"jobname": id->variables->jobname,
		"trip_at_end": (int)id->variables->trip_at_end,
		"enable_pneumatic_quads": (int)id->variables->enable_pneumatic_quads,
    "upper" : (int)id->variables->upper,
    "lower" : (int)id->variables->lower,
    "points" : (int)id->variables->points,
    "numerals" : (int)id->variables->numerals,
    "roman": (int)id->variables->roman,
    "italic": (int)id->variables->italic,
    "smallcaps": (int)id->variables->smallcaps,
    "bold": (int)id->variables->bold,
    "1" : (int)id->variables->s1,
    "2" : (int)id->variables->s2,
    "3" : (int)id->variables->s3,
    "4" : (int)id->variables->s4,
    "5" : (int)id->variables->s5,
    "s1q" : (int)id->variables->s1q,
    "s2q" : (int)id->variables->s2q,
    "s3q" : (int)id->variables->s3q,
    "s4q" : (int)id->variables->s4q,
    "s5q" : (int)id->variables->s5q,
		]);
}

public void do_generate_font(Request id, Response response, Template.View v, mixed ... args)
{
  // the job settings are stored in a mapping stored in the session object when we validate the file.
  // we can then retrieve them in the next step, here.
  id->variables = id->misc->session_variables["font_" + id->variables->job_id];
  m_delete(id->misc->session_variables, "font_" + id->variables->job_id);

  mapping settings = extract_font_settings(id);
  werror("%O\n", settings);	
  String.Buffer proof = String.Buffer();

  Monotype.Generator g = make_font(settings, id);	 

  response->set_data(g->generate_ribbon());
  response->set_header("content-disposition", "attachment; filename=\"" + 
    (id->variables->jobname || "untitled_font") + ".rib\"");	
  response->set_type("application/x-monotype-e-ribbon");
  response->set_charset("utf-8");
  id->misc->session_variables->generator = -1;
  id->misc->session_variables->generator = 0;
}

public void do_font(Request id, Response response, Template.View v, mixed ... args)
{
  object user = id->misc->session_variables->user;
  response->set_header("Cache-control", "no-cache");

  int job_id = random(9999999);
  id->misc->session_variables["font_" + job_id] = id->variables;

  mapping settings = extract_font_settings(id);
  String.Buffer proof = String.Buffer();

  Monotype.Generator g = make_font(settings, id);

  proof = render_proof(proof, g);
  id->misc->session_variables->generator = g;
	 
  v->add("job_id", job_id);
  v->add("result", proof);
  v->add("settings", settings);
  v->add("now", Calendar.now());

  response->set_charset("utf-8");
}

Monotype.Generator make_font(mapping settings, object id)
{
  units_since_js = 0;
  object g = Monotype.Generator(settings);
  g->set_hyphenation_rules(id->misc->session_variables->user["Preferences"]["hyphenation_rules"]["value"]);
  g->parse("");
  g->process_setting_buffer(1);
  int i = 0;


  // make sorts.
  object fs = app->load_font_scheme_by_id(settings->scheme, id->misc->session_variables->user);
  mapping scheme = Standards.JSON.decode(fs["definition"]);
  array parts = ({});  
  array alphabets = ({});

  foreach(({"upper", "lower", "points", "numerals"});;string part)
    if((int)id->variables[part])
      parts += ({part});

  foreach(({"roman", "italic", "bold", "smallcaps"});;string alphabet)
    if((int)id->variables[alphabet])
      alphabets += ({alphabet});

  foreach(alphabets;; string alphabet_type)
  {
    object template = g->create_styled_sort("X", 0.0);
    
    switch(alphabet_type)
    {
      case "roman":
        template->set_modifier(Monotype.MODIFIER_ROMAN);
        break;
      case "bold":
        template->set_modifier(Monotype.MODIFIER_BOLD);
        break;
      case "italic":
        template->set_modifier(Monotype.MODIFIER_ITALICS);
        break;
      case "smallcaps":
        template->set_modifier(Monotype.MODIFIER_SMALLCAPS);
        break;
    }

    foreach(parts;; string type)
    {
      array sorts = filter(scheme->items, lambda(mixed elem){
         return (elem->type == type);
        });

      sort(sorts->sort, sorts); 
      werror("sorts: %O\n", sorts);

      foreach(sorts;;mapping data)
      {
        // TODO add handling for non-roman sorts.
        object sort = g->create_styled_sort(data->sort, 0.0, template);
        add_font_sorts(g, sort, data->quantity);    
      }
    }
  }

  // make spaces.   
  while(i < 5)
  {
    string key = sprintf("%c", '1' + i);
    if(settings[key])
    {
      int gotit = 0;
      float width = calculate_space_width(i+1, settings->setwidth, settings->mould);
      foreach(settings->matcase->spaces;int w;)
      {
        float diff = width - (float)w;
        werror("looking for %O from %O, diff=%O\n", width, w, diff);
        if((diff <= 3.0) && (diff >= -2.0)) // we can usually adjust +/- 2 units (at set widths 12 or under).
        {
          gotit = 1;
          int sta = settings["s" + key + "q"];
          object s = Monotype.Sort(settings->matcase->spaces[w]);
          s->space_adjust = diff;

          add_font_sorts(g, s, sta, ":");

          break;
        }
      }
      if(!gotit)
      {
//        werror("spaces: %O\n", settings->matcase->spaces);
        throw(Error.Generic("Unable to find a suitable space for " + width + ". Available: " + String.implode_nicely(indices(settings->matcase->spaces)) + "\n"));
      }
    }
    i++;
  }
  if(!g->current_line->can_justify())
    g->current_line->add(g->create_styled_sort(":", 0.0));
  g->quad_out();
  g->new_line();
  return g;
}

int units_since_js;

void add_font_sorts(Monotype.Generator g, Monotype.Sort sort, int quantity, string|void separator)
{
  object errs = ADT.List();
  object mat = sort->get_mat(errs);
  
  if(units_since_js > (g->current_line->lineunits/3))
  {
    units_since_js = 0;
    if(mat->is_fs)
    {
      g->current_line->add(g->create_styled_sort(separator, 0.0));
    }
    g->current_line->add(g->JustifyingSpace,0);
    if(mat->is_fs)
    {
      g->current_line->add(g->create_styled_sort(separator, 0.0));
    }
  }

  while(quantity)
  {
    g->current_line->add(sort, 0, 0);
    if(units_since_js > (g->current_line->lineunits/3) && !g->current_line->linespaces)
    {
      units_since_js = 0;
      if(mat->is_fs)
      {
        g->current_line->add(g->create_styled_sort(separator, 0.0));
      }
      g->current_line->add(g->JustifyingSpace,0);
      if(mat->is_fs)
      {
        g->current_line->add(g->create_styled_sort(separator, 0.0));
      }
    }

    if(g->current_line->is_overset())
    {
      g->current_line->remove();

      if(g->current_line->can_justify())
      {
        g->new_line();
        units_since_js = 0;
      }
      else
      {           
        if(mat->is_fs)
        {
          g->current_line->add(g->create_styled_sort(separator, 0.0));
        }
        g->quad_out();
        if(catch(g->new_line()))
        {
          g->current_line->remove();
          quantity++;
          if(mat->is_fs)
          {
            g->current_line->add(g->create_styled_sort(separator, 0.0));
          }
          g->current_line->add(g->JustifyingSpace,0);
          g->quad_out();
          g->new_line();
          units_since_js = 0;
        }
      }
      g->current_line->add(sort, 0, 0);
    }
    if(mat && !mat->is_fs)
      units_since_js += (mat->set_width + sort->space_adjust);
    quantity --;
  };
  if(separator)
  {
    g->current_line->add(g->create_styled_sort(separator, 0.0));
  }
}

float calculate_space_width(int frac, float set, int mould)
{
   float units = 18.0/frac; // in terms of a set == mould size.
   return units * ((float)mould/set); // now, convert to units of the new set width.
}

public void font(Request id, Response response, Template.View v, mixed ... args)
{
    object user = id->misc->session_variables->user;

    array schemec = app->get_font_schemes();
    array schemes = ({});

    foreach(schemec;; object c)
    {
      if(c["owner"] == user || c["is_public"])
        schemes += ({ ({ (string)c["id"], c["name"] }) });
    }

    array mcac = app->get_mcas();
    array mcas = ({});

    foreach(mcac;; object c)
    {
      if(c["owner"] == user || c["is_public"])
        mcas += ({ ({ (string)c["id"], c["name"] }) });
    }

    array wedgec = app->get_wedges();
    array wedges = wedgec[*]["name"];

    werror("config: %O\n", id->variables);
   // werror("wedges: %O\n", wedges);

     //werror("matcases: %O\n", app->get_mcas());
      v->add("schemes", schemes);
      v->add("mcas", mcas);
      v->add("wedges", wedges);
      v->add("owner", user);

  	return;
}
