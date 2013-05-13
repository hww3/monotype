

int main(int argc, array argv)
{
  string f = Stdio.read_file(argv[1]);
  mapping g = getenv();
  f = replace(f, ({"$APP", "$HASH", "$SIZE", "$DATE", "$VERSION"}), ({g->APP, g->HASH, g->SIZE, g->DATE, g->VERSION}));
  write(f);
  return 0;
}
