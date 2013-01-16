inherit "CasterControllerOutlets";

object gx;
object mainWindow;
object AboutDialog;
object File_Open_Menu;
object View_JumpToLine_Menu;

static void create(int argc, array argv)
{
  GTK2.setup_gtk(argv);

  // load the UI.
  gx = GTK2.GladeXML("GTKCaster.glade");

  ::create();  

  register_preferences();

  // connect widgets with variables in this controller, based on widget name.
  foreach(gx->get_widget_prefix("");; object w)
  {
    string wn = gx->get_widget_name(w);
    
    if(has_index(this, wn)) 
    {
      werror("connecting widget %O\n", wn);
      this[wn] = w;
    }
  }

  // wire up signals based on functio names in this object.
  gx->signal_autoconnect(mkmapping(indices(this), values(this)), 0);

  toggleCaster(0);

  mainWindow->show_all();
  mainWindow->signal_connect("delete-event", do_exit);
}

int main(int argc, array argv)
{
  return -1;
}

void register_preferences()
{
}

int do_manual_pin_control_close(object widget)
{
  Driver->disableManualControl();
  CasterToggleButton->set_active(was_caster_enabled); 
  PinControlWindow->hide();
  return 1;
}

void do_manual_pin_control(object widget)
{
  if(!PinControlWindow) gx->get_widget("PinControlWindow");
  PinControlWindow->show_all();
  PinControlWindow->signal_connect("delete-event", do_manual_pin_control_close);

  was_caster_enabled = CasterToggleButton->get_active();
  CasterToggleButton->set_active(0);
  Driver->enableManualControl();
  IgnoreCycleButton_toggled_cb(IgnoreCycleButton);
  allOff(widget);
}

void IgnoreCycleButton_toggled_cb(object widget)
{
  int icc = widget->get_active();
  if(icc)
  {
    Driver->forceOn();
  }
  else
  {
    Driver->forceOff();
  }

}

void manual_check_toggled(object widget)
{
  int state = widget->get_active();
  string pin = (string)widget->get_name()[1..];
  werror("checkbox %O toggled %O\n", pin, state);

  if(state)
    Driver->enablePin(widget, pin);
  else
    Driver->disablePin(widget, pin);
}


void do_jump(mixed ... args)
{
  JumpToLineBox->show_all();
  int rv = JumpToLineBox->run();
werror("rv: %O\n", rv);
  if(rv == 1)
  {
    int line_to_jump_to = (int)gx->get_widget("JumpLineNumber")->get_text();
    Driver->jump_to_line((int)line_to_jump_to);
  }

  JumpToLineBox->hide();
}

void do_about(mixed ... args)
{
  AboutDialog->show_all();
  AboutDialog->run();
  AboutDialog->hide();
}

void do_exit(mixed ... args)
{
  exit(0);
}

void allOff(object b)
{
        werror("allOff(%O)\n", b);
        foreach(buttonstotouch;; string but)
        {
          if(this["c" + but])
            this["c" + but]->set_active(0);
        }
        Driver->allOff();
}

void allOn(object b)
{
        werror("allOn(%O)\n", b);
        foreach(buttonstotouch;; string but)
        {
          if(this["c" + but])
            this["c" + but]->set_active(1);
        }
        Driver->allOn();
}

void AllOff_clicked_cb(object widget)
{
  allOff(widget);
}

void AllOn_clicked_cb(object widget)
{
  allOn(widget);
}

void mpc_button_press_event_cb(object widget)
{
  string id = widget->get_name();
  object w = this["c" + id];
  w->set_active(!w->get_active());
}

void SkipBackwardButton_clicked_cb(object widget)
{
  Driver->backwardLine();
}

void SkipForwardButton_clicked_cb(object widget)
{
  Driver->forwardLine();
}

void SkipBeginButton_clicked_cb(object widget)
{
  Driver->rewindRibbon();
}

void CasterToggleButton_toggled_cb(object widget)
{
  int state = widget->get_active();
//  werror("CasterTogglebutton_toggled_cb(%O, %O)\n", widget, state);
  toggleCaster(state);
}

void LoadJobButton_clicked_cb(mixed ... args)
{
  string file;

  object fc = GTK2.FileChooserDialog("File selector", 0, GTK2.FILE_CHOOSER_ACTION_OPEN, ({
    (["text": GTK2.STOCK_CANCEL, "id": GTK2.RESPONSE_CANCEL]),
    (["text": GTK2.STOCK_OK, "id": GTK2.RESPONSE_OK])
  }) );

  // only load .rib files
  object ff = GTK2.FileFilter();
  ff->add_pattern("*.rib");
  ff->set_name("eRibbon Files");
  fc->add_filter(ff);
  int rv = fc->run();

  if(rv == GTK2.RESPONSE_OK)
  {
    file = fc->get_filename();
    jobinfo = Driver->loadRibbon(file);
    set_job_info();
    CasterToggleButton->set_sensitive(1);
    JumpToLineItem->set_sensitive(1);
//  app->mainMenu()->update();

  }
  fc->destroy();
}


void set_job_info()
{
  JobName->set_label(jobinfo->name);
  Face->set_label(jobinfo->face);
  Wedge->set_label(jobinfo->wedge + "/" + jobinfo->set);
  Mould->set_label(jobinfo->mould);
  LineLength->set_label(jobinfo->linelength + " pica");
  Thermometer->set_fraction(0.0);
}

//
// Driver interface functions
//

int alert(string title, string body)
{
  object m = GTK2.MessageDialog(1, GTK2.MESSAGE_WARNING, GTK2.BUTTONS_OK, body);
  m->set_title(title);
  int rv = m->run();

  m->destroy();
  m = 0;
  return rv;
}

void setCycleIndicator(int(0..1) status)
{
  if(status)
    CycleIndicator->set_sensitive(1);
  else
    CycleIndicator->set_sensitive(0);
}

  void setLineContents(string s)
  {
    LineContentsLabel->set_label(s);
  }

  void setLineStatus(string s)
  {
    CurrentLine->set_label(s);
  }

  void setStatus(string s)
  {
    Status->set_label(s);
  }

  void updateThermometer(float percent)
  {
    Thermometer->set_fraction(percent/100.0);
  }

  void toggleCaster(int (0..1) state)
  {
    CasterToggleButton->set_active(state);
    CasterToggleButton->set_label(({"Start", "Stop"})[state]);

    LoadJobButton->set_sensitive(!state);
    File_Open_Menu->set_sensitive(!state);
    SkipForwardButton->set_sensitive(state);
    SkipBackwardButton->set_sensitive(state);
    SkipBeginButton->set_sensitive(state);

    if(state) 
      Driver->start();
    else 
      Driver->stop();

//    
//    toggleCaster_(state);
  }

