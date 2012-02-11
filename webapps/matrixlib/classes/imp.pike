int main()
{

 array x = Stdio.read_file("matrixlib/sources/bmono.csv")/"\n";
 array e = ({});
 int ce = -1;
 for(int i = 1; i < sizeof(x); i++)
 {
  array ent = x[i]/",";
werror("e[0]=%O\n", ent[0]);
  if((int)(ent[0]-" "))
  {
    mapping c;
    c = ([]);
    c->series = ent[0];
    c->name = ent[1];
    c->comments = ent[2];
    c->ua = ent[3];
    ce++;
    e += ({c});
  }
  else
  {
    string v = (ent-({""}))*"\n"; 
    e[ce]->comments += ("\n" + v);
  }

 }

  foreach(e;; mapping s)
  {
    object ent = matrixlib.Objects.Series();
werror("saving: %O\n", s);
     s->series = "B" + s->series;
    if(search(s->comments, "Cyrillic") != -1) s->series += "C";
    ent->set_atomic(s);
  }
return 0;
}
