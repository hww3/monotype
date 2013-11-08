protected object mat;
float space_adjust;

protected void create(object _mat)
{
  mat = _mat;
}

object(this_program) clone(string sort)
{
  return this_program(mat);
}

string get_modifier()
{
  return "";
}

object get_mat(object errors)
{
  return mat;
}

float get_set_width()
{
  object m = get_mat(ADT.List());
    
  if(!m) return 0;
  
  else return m->get_set_width() + space_adjust;
}

static string _sprintf(mixed t)
{
  return "Monotype.Sort(" + sprintf("%O", mat) + ")";
}
