inherit Monotype.Generator;

array raster_data;
Monotype.Line raster_line;

static void create(mapping settings, string shape)
{
  array cd = render(shape);
  raster_data = generate_columns(cd);
  
  int x,w = 0;
  while(raster_data[x] && !raster_data[x]->newline)
  {
    w+=raster_data[x]->count;
    x++;
  }
  
  ::create(settings + (["lineunits": w]));
  config->rasterlength = config->lineunits; // the width of the raster page.
  werror("raster_length: %O\n", config->rasterlength);
  werror("%O\n", raster_data);
  new_line(1);
}

void insert_header()
{}
void insert_footer()
{}
  
// add the current line to the job, if it's justifyable.
void new_line(int|void newpara)
{
//throw(Error.Generic("new_line()\n"));
object cdata;
if(current_line)
{
  if(!((float)current_line->linelength > 0.0))
  {
    werror("WARNING: new_line() called without any content.\n");
    return 0;
  }    
  if(!current_line->linespaces && (float)current_line->linelength != (float)current_line->lineunits)
  {
      throw(Error.Generic(sprintf("Off-length line without justifying spaces: need %d units to justify, line has %.1f units. Consider adding a justifying space to line - %s\n", 
		current_line->lineunits, current_line->linelength, (string)current_line)));
  }
  else if(current_line->linespaces && !current_line->can_justify()) 
    throw(Error.Generic(sprintf("Unable to justify line; %f length with %f units, %d spaces, justification code would be: %d/%d, text on line is %s\n", (float)current_line->linelength, (float)current_line->lineunits, current_line->linespaces, current_line->big, current_line->little, string_to_utf8((string)current_line))));
}
  if(!raster_line)
  {
    object ocl = current_line;
    config->lineunits = config->rasterlength;
    make_new_line();
    raster_line = current_line;
    current_line = ocl;
    
    cdata = apply_spaces(); 
  }

  if(current_line)
  {
 //   throw(Error.Generic("adding\n"));
    raster_line->add(current_line);
  }


  if(!cdata) cdata = apply_spaces();
  config->lineunits = cdata?cdata->count:config->rasterlength;
//werror("line: %O->%O\n", lines[-1], lines[-1]->elements);

//  if(config->page_length && intp(config->page_length) && !(linesonpage%config->page_length))
//  {
//  	break_page(newpara);
//  }
//  else
    make_new_line(newpara);
}


object cdata;

object apply_spaces()
{
  object cdata;
  if(!sizeof(raster_data))
  {
    cdata = 0;
    if(raster_line->linelength == 0.0) return 0;
    raster_line->finalized = 1;
    lines += ({raster_line});
         
    config->lineunits = config->rasterlength;
    current_line = 0;
    make_new_line();
    raster_line = current_line;  
    return 0;
  }

do
{
  if(!sizeof(raster_data))
  {
    cdata = 0;
    if(raster_line->linelength == 0.0) return 0;
    
    raster_line->finalized = 1;
    lines += ({raster_line});
         
    config->lineunits = config->rasterlength;
    current_line = 0;
    make_new_line();
    raster_line = current_line;
  
    break;
  }
  cdata = raster_data[0];
  raster_data = raster_data[1..];
  if(cdata->newline)
  {
    raster_line->finalized = 1;
    lines += ({raster_line});
         
    config->lineunits = config->rasterlength;
    current_line = 0;
    make_new_line();
    raster_line = current_line;
  }
  else if(cdata->space)
  {
    current_line = raster_line;
    low_quad_out(cdata->count);
    current_line = 0;
  }    
} while(!cdata->word);

 return cdata;
}

array generate_columns(array cd)
{
  array cols = ({});
  werror("cd: %O\n", cd);
  foreach(cd; int cn; string d)
  {
    array col = ({});
      int count;
      string last = "";
      foreach(d/""; int x; string ch)
      {
        if(ch == "*")
        {
          if(last != ch && count)
          {
            cols += ({space(count)});
            count = 18;
          }
          else count += 18;
          last = ch;
        }
        else if(ch == " ")
        {
          if(last != ch && count)
          {
            cols += ({word(count)});
            count = 18;
          }
          else count += 18;
          last = ch;
        }
      }
      if(count)
      {
        if(last == "*")
          cols += ({word(count)});
        else
          cols += ({space(count)});
      }
      cols += ({newline()});
  }
  
  return cols;
}

class word(int count)
{
  constant word = 1;
  protected mixed _sprintf(mixed f)
  {
    return "word(" + count + ")";
  }
}

class space(int count)
{
  constant space = 1;
  protected mixed _sprintf(mixed f)
  {
    return "space(" + count + ")";
  }
}

class newline()
{
  constant newline = 1;
  protected mixed _sprintf(mixed f)
  {
    return "newline()";
  }
  
}
// render some text as text
array render(string text)
{
  Image.Fonts.set_font_dirs(({"/System/Library/Fonts"}));
  object face = Image.FreeType.Face("/System/Library/Fonts/Helvetica.dfont", 5);
  object font = Image.Fonts.FTFont(face, 48, "Helvetica.dfont");
  object i = font->write(text);
  array d = allocate(i->ysize());
  int x,y;
  for(y = 0; y < i->ysize(); y++) {
    string r = "";
    for(x = 0; x < i->xsize(); x++) {
      if(i->getpixel(x,y)[0] > 127) r+="*"; else/* if(i->getpixel(x,y)[0] > 100) r+="."; else */ r+=" ";
    }
    d[y] = r;
  }
 
  // remove empty lines from above and below the text.
  array pd = reverse(clean(reverse(clean(d))));
 
  write(pd *"\n");
 
  return pd;
 }
 
  
  // remove empty lines at the top of the array. 
 array clean(array d)
 {
   array pd = ({});
   int hd = 0;
   foreach(d;;string r)
   {
     if((r-" ") == "" && !hd)
      continue;  
     else 
      {hd = 1; pd+=({r});}
   }
   return pd;
 }