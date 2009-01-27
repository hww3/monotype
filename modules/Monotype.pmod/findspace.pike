array realSol;

int main(int argc, array argv)
{
  object set = box(({ /* 5 elements */
    5,
    6,
    9,
    14,
    18
})
);
  object sol = box(({}));


 // werror("%O\n",  findSpace((int)argv[1],set,sol)?realSol:0);
  return 0;
}

array simple_find_space(int amount, mapping spaces)
{
	object set, sol;
	array sv = indices(spaces);
	multiset sm = (multiset)sv;
	// the 18 unit wedge position is often worn, 
	// so we minimize error by mixing it with 9 unit spaces when possible.
	if(sm[18] && sm[9])
	  sv += ({27});
	set = box(sort(sv));
	sol = box(({}));
	
//	werror("spaces: %O %O\n", amount, spaces);
//	if(findSpace(amount, set, sol) && sizeof(sol->vals))
	
    if(!findSpace(amount,set,sol))
      werror(sprintf("failed to find space=%O, sol=%O\n", amount, sol->vals));

	array x = realSol||({});
	array z = x - ({27});
	array y = x - z;
	
	foreach(y;;)
	  z = ({9, 18}) + z;
	
//	  return sol->vals;
//	else return 0;
  return z;
}

public int findSpace(int space, object set, object sol)
{
  //werror("findSpace(space=%O, set=%O, sol=%O)\n", space, set->vals, sol->vals);
  if(!sizeof(set->vals)) return 0;

  int largestItem = sizeof(set->vals)?set->vals[-1]:0;
  int lastItem = largestItem;

  if(lastItem <= space)
  {
    int remainder = space % lastItem;
    if(remainder == 0)
    {
      int count = space / lastItem;
      for(int j = 0; j < count; j++)
      {
         sol->vals += ({lastItem});
      }
      sol->vals = sort(sol->vals);
      realSol = sol->vals;
      return sol->vals;
    }

    if(sizeof(set->vals) < 1) return 0;
    int count = space / lastItem;
//werror("sol->vals=(%O)\n", sol->vals);
    object solClone = box(copy_value(sol->vals));
    for(int j = 0; j < count; j++)
      solClone->vals += ({ lastItem });
    object setClone = box(copy_value(set->vals));
    setClone->vals = setClone->vals - (({setClone->vals[-1]}));

    if(!findSpace(remainder, setClone, solClone)) 
    {
      if(sizeof(setClone->vals) > 0) 
      {
        int nextLargestItem = setClone->vals[-1];
        if(remainder >= nextLargestItem)
        {
          return findSpace(space, setClone, sol);
        }
        else
        {
          if(sizeof(solClone->vals) > 0)
          {
            solClone->vals = solClone->vals[0..sizeof(solClone->vals)-2];
          }
          else
          {
            solClone = box(({}));
          }
          if(!findSpace(remainder + lastItem, setClone, solClone))
          {
            return findSpace(space, setClone, sol);
          }
          else return solClone->vals;
        }
      } else { return 0; }
    } else return sol->vals;

  } else
  {
    object setClone = box(copy_value(set->vals));
    setClone->vals = setClone->vals - ({largestItem});
    return findSpace(space, setClone, sol);
  }
}


class box(array vals)
{
}
