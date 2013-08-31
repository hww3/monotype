import Fins;
inherit "mono_doccontroller";

int __quiet = 1;

void start()
{
  before_filter(app->admin_user_filter);
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
  return ([
		"justification": (int)id->variables->justification,
		"unit_adding": (int)id->variables->unitadding,
		"unit_shift": (int)(id->variables->unit_shift),
		"mould": (int)id->variables->points,
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

public void do_validate(Request id, Response response, Template.View v, mixed ... args)
{
  object user = id->misc->session_variables->user;

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
  
	if(id->variables->save_config)
	{
	  object rc;
	  
	  string name = String.trim_all_whites(id->variables->name || "");
	  
	  if(!name) 
	  { 
	    response->flash("msg", "No template name specified.");
	    response->redirect_temp(generate);  
	  }
	  
    array rv = Fins.Model.find.ribbon_configs((["name": name, "User": user]));
    if(sizeof(rv))
      rc = rv[0]; 
    if(rc)
      throw(Error.Generic("Configuration for " + user["username"] + " with name=" + name + " already exists.\n"));
	  
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
    
    object settings = Keyboard.Objects.Ribbon_config();
    settings["name"] = name;
    settings["definition"] = se;
    settings["User"] = user;
    settings->save();
    
	  response->flash("msg", "Settings saved as " + name + ".");
	  response->redirect_temp(generate, ({}), (["load_config": 1, "config": settings["id"] ]));
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
	
	//werror("%O\n", id->variables);
	int job_id = random(9999999);
	id->misc->session_variables["job_" + job_id] = id->variables;
	mapping settings = extract_settings(id);
	
	// we don't need this to be shown in the "soft proof".
  m_delete(settings, "trip_at_end");
  
	int max_red = 2;
        if(settings->setwidth > 12.0)	
	  max_red = 1;
		
	string data;
	if(id->variables->input_type=="file") data = /*utf8_to_string*/(id->variables["input-file"]);
	else data = (id->variables->input_text);
	// = "Now is the time for all good men to come to the aid of their country. Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go.<qo>";
	
	object g, b;
  Error.Generic err;
  
  mixed parse_time = gauge {
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

	int units;
        if(g->lines && sizeof(g->lines)) units = g->lines[-1]->units;
        else if(g->current_line) units = g->current_line->units;

	b+="<div style=\"clear: left\">";
	b+=("<div style=\"position:relative; float:left; width:50px\">Line</div><div style=\"position:relative; float:left; width:" 
		+ units + "px\">&nbsp;</div><div></div><div>Just Code / Comments</div>");
	b+=("</div>");

//	foreach(g->lines + (err?({g->current_line}):({})); int i; mixed line)
  mixed render_time = gauge {
	foreach(g->lines; int i; mixed line)
	{
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

		foreach(line->render_line();int col; mixed e)
		{
	//	  if(e->is_real_js && line->combined_space)
	//	    continue;
		 if(e->is_real_js)
		  {
			if(tobeadded != "")
			{
			  b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + tobeaddedwidth + "px\">" + tobeadded + "</div>");
			  tobeadded = "";
			  tobeaddedwidth = 0;
			}
			// need some better work on this.
		    int w;
		    if(!line->combined_space)
		    {
		      w = e->matrix->get_set_width();
		      w = (w-max_red + line->units);
		    }
		    else
		    {
		      w = line->units;
	//	      throw(Error.Generic("combined space " + w + "\n"));
	      }
		    setonline+=w;

 		// spill is used to even out the display lines, as we're not able to depict fractional units accurately on the screen.
		    spill += (line->units-floor(line->units));
		if(spill > 1.0) { w+=1; spill -=1.0; }

		total_set += (e->matrix->get_set_width()-max_red);
		    b += ("<div style=\"position:relative; float:left; background:" + (!line->combined_space?"orange":"red") + "; width:" + (int)(w) + "px\"> &nbsp; </div>");
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
		    int w = e->get_set_width();
		    setonline+=w;
		    mod++;
		if(mod%2)					    
		    b += ("<div style=\"position:relative; float:left; background:pink; width:" + w + "px\">&nbsp;</div>");
		else
		    b += ("<div style=\"position:relative; float:left; background:lightpink; width:" + w + "px\">&nbsp;</div>");
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
			  b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + tobeaddedwidth + "px\">" + tobeadded + "</div>");
			  tobeadded = "";
			  tobeaddedwidth = 0;
			}
		b+=(" &nbsp; " /* +total_set + " " +(setonline) */ + " &lt;== " + line->big + " " + line->little /*+ " " + line->units*/ + "[" + line->line_on_page + "]");
		b+=" [<a onClick=\"showCodes(" + i + ", '" + action_url(get_line, ({(string)i})) + "')\">Codes</a>]";
    
		if(line->errors && sizeof(line->errors))
		  b+= ((array)line->errors * ", ");
		b+=("</div>\n");
	}
};
werror("render_time: %O\n", render_time);

    v->add("job_id", job_id);
    v->add("result", b);

    response->set_charset("utf-8");
	
//	string s = g->generate_ribbon();
//	response->set_data(b);
	return;
}

