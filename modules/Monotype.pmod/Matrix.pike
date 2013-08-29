import Public.Parser.XML2;


  string series;
  int size;
  string style;
  string character;
  string activator;
  float set_width;
  int row_pos;
  string col_pos;
  int is_js;
  int is_fs;
  int is_hs;
  
  function report_problem;

  static mixed cast(string to)
  {
    if(to == "mapping")
    {
      mapping m = ([]);
      foreach(indices(this);; string k)
        if(!functionp(this[k])) m[k] = this[k];
      return m;
    }

    else throw(Error.Generic("Casting Matrix to " + to + " not supported."));
  }

  static void create(void|Node n, void|function report)
  {
    report_problem = report;
    if(n) 
      load(n);
    report_problem = 0;
  }
  
  this_program clone()
  {
    object nm = this_program();
    mapping m = (mapping)this;
    foreach(m; string k; mixed v)
      nm[k] = v;
      
    return nm;
  }

  int load(Node n, void|function report)
  {
    if(n->get_node_name() != "matrix")
      error("invalid matrix data.\n");
 
    mapping a = n->get_attributes();

	if(a->space && a->space == "fixed") is_fs = 1; 
	else if(a->space && a->space == "justifying") is_js = 1; 
    if(a->series) series = a->series;
    if(a->size) size = (int)(a->size);
    if(a->weight && a->weight!="0") style = (strlen(a->weight)?a->weight:"R");
    if(a->character) character = a->character;
    if(a->activator) activator = a->activator;
    if(a->set_width) set_set_width((float)(a->set_width), 1);
    return 1;
  }

  Node dump()
  {
    Node n = new_xml("1.0", "matrix");
  
    if(series)
      n->set_attribute("series", series);
    if(size)
      n->set_attribute("size", (string)size);
    if(style && style != "0")
      n->set_attribute("weight", style);
    if(character)
      n->set_attribute("character", character);
    if(set_width)
      n->set_attribute("set_width", (string)set_width);
     if(is_fs)
        n->set_attribute("space", "fixed");
      else if(is_js)
        n->set_attribute("space", "justifying");
      else if(activator)
        n->set_attribute("activator", activator);
	  
    return n;
  }

  int is_space()
  {
	return is_js || is_fs;
  }

  

  float get_set_width()
  {
    return set_width;
  }

  string get_activator()
  {
    return activator;
  }
  
  string get_character()
  {  
    return character;
  }

  string get_style()
  { 
    return style;
  }
  
  int get_size()
  {
    return size;
  }
  
  string get_series()
  {
    return series;
  }

  void set_set_width(float width, int|void liberal)
  {
    int w, f;
    
		sscanf((string)width, "%d.%d", w, f);
	//	werror("sa: %s, w: %d, f: %d\n", sa, w, f);
		if(!(<0, 5>)[f])
		{
		  if(liberal && report_problem)
        report_problem("Invalid adjustment " + width + ". Only whole and half unit adjustments allowed.\n");
		  else
		    throw(Error.Generic("Invalid adjustment " + width + ". Only whole and half unit adjustments allowed.\n"));
    }		
    set_width = width;
  }

  void set_activator(string a)
  {
    activator = a;
  }
  
  void set_character(string c)
  {  
    character = c;
  }

  void set_style(string s)
  { 
    style = s;
  }
  
  void set_size(int s)
  {
    size = s;
  }
  
  void set_series(string s)
  {
    series = s;
  }

  void set_position(int row, string col)
  {
    row_pos = row;
    col_pos = col; 
  }

  mixed _sprintf(mixed x)
  {
    if(is_fs)
      return "Matrix(FixedSpace)";
    else if(is_js)
      return "Matrix(JustifyingSpace)";
    else
      return "Matrix(" + style + "/" + activator + ")";
  }
