inherit .Sort;

constant punctuation_subset = (<".", ",", ":", ";", "'", "’", "‘", "(", ")", "[", "]", "“", "”", "!", "?", "-", "–">);

object mca;
mapping config;
object mat;

int modifier;
int hyphenation_disabled;

string activator;
string character;

constant is_styled_sort = 1;

string _sprintf(mixed t)
{
  return "StyledSort(" + get_modifier() + "/" + character  + ") ";
}

protected void create(string sort, object m, mapping c, int isitalics, int isbold, int issmallcaps, float adjust, int nohyphenation)
{
  create_modifier(isitalics, isbold, issmallcaps);

  activator = sort;
  space_adjust = adjust;
  mca = m;
  config = c;
  hyphenation_disabled = nohyphenation;

  mat = get_mat(ADT.List());
  if(mat) character = mat->character;
  else character = "";
}

object(this_program) clone(string sort)
{
  object s = this_program(sort, mca, config,
      modifier&Monotype.MODIFIER_ITALICS,
      modifier&Monotype.MODIFIER_BOLD,
      modifier&Monotype.MODIFIER_SMALLCAPS,
      space_adjust,hyphenation_disabled);
//  s->space_adjust = space_adjust;
//  s->modifier = modifier;
//  s->character = character;
//  s->hyphenation_disabled = hyphenation_disabled;
  return s;  
}

protected void create_modifier(int isitalics, int isbold, int issmallcaps)
{
  if(isitalics) modifier|=Monotype.MODIFIER_ITALICS;
	if(isbold) modifier|=Monotype.MODIFIER_BOLD;
	if(issmallcaps) modifier|=Monotype.MODIFIER_SMALLCAPS;
}

string get_modifier()
{
  if(modifier & Monotype.MODIFIER_ITALICS) return "I";
  if(modifier & Monotype.MODIFIER_BOLD) return "B";
  if(modifier & Monotype.MODIFIER_SMALLCAPS) return "S";
  else return "R";
}

object get_mat(object errors)
{
  if(mat) return mat;
  
  string code = activator;
  
  if(modifier & Monotype.MODIFIER_SMALLCAPS && config->allow_lowercase_smallcaps)
  {
    code = upper_case(code);
  }
  
  if(modifier&Monotype.MODIFIER_ITALICS)
    code = "I|" + code;	 
  else if(modifier&Monotype.MODIFIER_SMALLCAPS)
    code = "S|" + code;
  else if(modifier&Monotype.MODIFIER_BOLD)
    code = "B|" + code;

  mat = mca->elements[code];
  
  if(!mat && ((modifier&Monotype.MODIFIER_ITALICS) || (modifier&Monotype.MODIFIER_SMALLCAPS))&& config->allow_punctuation_substitution && punctuation_subset[activator])
  {
    if(mat = mca->elements[activator])
	    errors->append("Substituted activator " + (activator) + " from roman alphabet.");
	  else
	    errors->append("Unable to substitute activator [" + (activator) + "] from roman alphabet.");
  }
  
  if(!mat)
  { 
    errors->append("Requested activator [" + 
	    (activator) + "] not in MCA.\n"); 
	  werror("invalid activator %O/%O\n", string_to_utf8(activator),code);
  }
  
  return mat;
}
