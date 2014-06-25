

array solutions = ({});
int variations;
array(int) findspaces(int tofind, mapping spaces)
{

        array sv = indices(spaces);
        multiset sm = (multiset)sv;
        // the 18 unit wedge position is often worn,
        // so we minimize error by mixing it with 9 unit spaces when possible.
        if(sm[18] && sm[9])  
          sv += ({27}); 
// werror("iterative find: %d with %O\n", tofind, sv);
  dofind(tofind, sv, ({}));
solutions = Array.sort_array(solutions,lambda(array a, array b){return sizeof(a)>sizeof(b);});
// werror("found %d solutions\n", sizeof(solutions));
array rs = ({});
if(!sizeof(solutions)) return 0;
rs += ({solutions[0]});
int x, i;
i=1;
do
{

  if(sizeof(solutions) <=i && sizeof(solutions[i]) == sizeof(solutions[0])) rs+=({solutions[i]}); 
  else x = 0;
i++;
}
while(x);

return rs[0];
}


array dofind(int tofind, array spaces, array current_prefix)
{
variations++;
  foreach(spaces;;int val)
  {
    //the easy case.
    array sol;
    if(sol = findnorem(tofind, val))
    {
      solutions+=({sort(current_prefix + sol)});
      continue;
    }    
    // starting with the smallest amount of the current space size, we find all of the combinations

    array x = ({});
    for(int i = (tofind/val); i>=0; i--)
    {
       x = allocate(i, val);
       dofind(tofind-Array.sum(x), spaces-=({val}), x+current_prefix);
       
    }

  }
}

array findnorem(int tofind, int val)
{
    if(!(tofind%val))
    {
      array sol = allocate(tofind/val, val);
      return sol;
    }

  else 
{
return 0;
}
}
