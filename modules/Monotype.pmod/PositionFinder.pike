
  float current_pos = 0.0;

//! calculate the position that each sort /ends/.
//! 
//! @returns an array containing floats or arrays (for sub-lines) indicating
//!   the unit position that the given element occupies.
array calculate_positions(Monotype.Line line)
{
  array elements = line->elements;
  array pos = allocate(sizeof(elements));
  ADT.List errs = ADT.List();

  float spacewidth; 
  spacewidth = line->calc_justspace(1) + line->min_space_units;
//  werror("spacewidth: %O\n", spacewidth);
  foreach(elements; int x; mixed elem)
  {
    if(Program.implements(object_program(elem), Monotype.Line))
    {
      pos[x] = calculate_positions(elem);
    }
    else if(elem->is_real_js)
    {
      current_pos += spacewidth;
      pos[x] = current_pos;
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

