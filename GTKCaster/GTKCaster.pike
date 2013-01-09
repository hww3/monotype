object gx;

int main(int argc, array argv)
{
  GTK2.setup_gtk(argv);

  gx = GTK2.GladeXML("Caster.glade");
  object window = gx->get_widget("window1");
  werror("window: %O\n", window);
  window->show_all();
  window->signal_connect("delete-event", do_exit);
  return -1;
}


void do_exit(mixed ... args)
{
  exit(0);
}
