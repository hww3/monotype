import Fins;

inherit DocController;

void start()
{
//  before_filter(app->admin_user_filter);
}

//int __quiet = 1;

public void index(Request id, Response response, Template.View v, mixed ... args)
{
	return;
}

public void generate(Request id, Response response, Template.View v, mixed ... args)
{
	array m = app->get_mcas();
    v->add("mcas", m);
    v->add("wedges", app->get_wedges());
  
	return;
}

public void get_wedge_for_mca(Request id, Response response, Template.View v, mixed args)
{
	string w;
	werror("args: %O\n", args);
	
	object mca = app->load_matcase(args[0]);

    if(!mca) w = "000";

    else w = mca->wedge;
	werror("wedge: " + w);
	response->set_data(w);
}

public void do_generate(Request id, Response response, Template.View v, mixed ... args)
{
    // the job settings are stored in a mapping stored in the session object when we validate the file.
    // we can then retrieve them in the next step, here.
	id->variables = id->misc->session_variables["job_" + id->variables->job_id];
werror("job_id is %d\n", (int)id->variables->job_id);
	m_delete(id->misc->session_variables, "job_" + id->variables->job_id);

	mapping settings = ([
		"justification": (int)id->variables->justification,
		"unit_adding": (int)id->variables->unitadding,
		"unit_shift": (int)(id->variables->unitshift?id->variables->unitshift_units:0),
		"mould": (int)id->variables->points,
		"pointsystem": (float)id->variables->pointsystem,
		"setwidth": (float)id->variables->set,
		"linelengthp": (float)id->variables->linelength,
		"stopbar": app->load_wedge(id->variables->wedge),
		"matcase": app->load_matcase(id->variables->mca),
		"jobname": id->variables->jobname,
		"dict_dir": combine_path(app->config->app_dir, "config"),
                "lang": id->variables->lang,
                "hyphenate": (int)id->variables->hyphenate,
		"min_little": (int)(id->variables->min_just/"/")[1], 
		"min_big": (int)(id->variables->min_just/"/")[1]
		]);
		
		string data;
		if(id->variables->input_type=="file") data = id->variables["input-file"];
		else data = id->variables->input_text;
		// = "Now is the time for all good men to come to the aid of their country. Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go.<qo>";
	
	object g = Monotype.Generator(settings);
	g->parse(data);

    response->set_data(g->generate_ribbon());
    response->set_header("content-disposition", "attachment; filename=" + 
        id->variables->jobname + ".rib");	
    response->set_type("application/x-monotype-e-ribbon");
    response->set_charset("utf-8");
}

public void do_validate(Request id, Response response, Template.View v, mixed ... args)
{
	
	werror("%O\n", id->variables);
	int job_id = random(9999999);
	id->misc->session_variables["job_" + job_id] = id->variables;
	
	mapping settings = ([
		"justification": (int)id->variables->justification,
		"unit_adding": (int)id->variables->unitadding,
		"unit_shift": (int)(id->variables->unitshift?id->variables->unitshift_units:0),
		"mould": (int)id->variables->points,
		"setwidth": (float)id->variables->set,
                "pointsystem": (float)id->variables->pointsystem,
		"linelengthp": (float)id->variables->linelength,
		"stopbar": app->load_wedge(id->variables->wedge),
		"matcase": app->load_matcase(id->variables->mca),
		"jobname": id->variables->jobname,
		"dict_dir": combine_path(app->config->app_dir, "config"),
                "lang": id->variables->lang,
                "hyphenate": (int)id->variables->hyphenate,
		"min_little": (int)(id->variables->min_just/"/")[1], 
		"min_big": (int)(id->variables->min_just/"/")[0]
		]);
		
		string data;
		if(id->variables->input_type=="file") data = id->variables["input-file"];
		else data = id->variables->input_text;
		// = "Now is the time for all good men to come to the aid of their country. Mary had a little lamb, its fleece was white as snow. Everywhere that mary went, the lamb was sure to go.<qo>";
	
	object g = Monotype.Generator(settings);

	Error.Generic err = Error.mkerror(catch(g->parse(data)));
	
	object b = String.Buffer();

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
	}

	int units;
        if(g->lines && sizeof(g->lines)) units = g->lines[-1]->units;
        else if(g->current_line) units = g->current_line->units;

	b+="<div style=\"clear: left\">";
	b+=("<div style=\"position:relative; float:left; width:35px\">Line</div><div style=\"position:relative; float:left; width:" 
		+ units + "px\">&nbsp;</div><div>Just Code / Comments</div>");
	b+=("</div>");

//	foreach(g->lines + (err?({g->current_line}):({})); int i; mixed line)
	foreach(g->lines; int i; mixed line)
	{
		int setonline;
		int last_was_space = 0;
		int last_set;
		b+="<div style=\"clear: left\">";
		b+=("<div style=\"position:relative; float:left; width:35px\">" + (i+1) + "</div>");
		string tobeadded = "";
		int tobeaddedwidth = 0;
		int total_set; 
		float spill =0.00;

		foreach(line->elements;int col; mixed e)
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
		    int w = e->matrix->get_set_width();
		    w = (w-2 + line->units);
		    setonline+=w;

 		// spill is used to even out the display lines, as we're not able to depict fractional units accurately on the screen.
		    spill += (line->units-floor(line->units));
		if(spill > 1.0) { w+=1; spill -=1.0; }

		total_set += (e->matrix->get_set_width()-2);
		    b += ("<div style=\"position:relative; float:left; background:orange; width:" + (int)(w) + "px\"> &nbsp; </div>");
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
		    
		    b += ("<div style=\"position:relative; float:left; background:pink; width:" + w + "px\">&nbsp;</div>");
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
			    
			 if(sizeof(e->character) > 1) 
			  tobeadded += ("<u>" + string_to_utf8(ch||" &nbsp; ") + "</u>");
			 else
  			   tobeadded += string_to_utf8(ch||" &nbsp; ");
		  }
		
//		  if((total_set-last_set) <= 2) werror("%d %d whee!\n", i, col);
		  last_set = total_set;
        }		
		
			if(tobeadded != "")
			{
			  b+= ("<div style=\"align:center; background: grey; position:relative; float:left; width:" + tobeaddedwidth + "px\">" + tobeadded + "</div>");
			  tobeadded = "";
			  tobeaddedwidth = 0;
			}
		b+=(" &nbsp; " /* +total_set + " " +(setonline) */ + " &lt;== " + line->big + " " + line->little /*+ " " + line->units*/);
		if(line->errors && sizeof(line->errors))
		  b+= (line->errors * ", ");
		b+=("</div>\n");
	}

    v->add("job_id", job_id);
    v->add("result", b);

    response->set_charset("utf-8");
	
//	string s = g->generate_ribbon();
//	response->set_data(b);
	return;
}
