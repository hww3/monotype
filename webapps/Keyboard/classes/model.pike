inherit Fins.FinsModel;

object get_context(mapping _config)
{
  object c;

  // are we running in a desktop mode?
  if(all_constants()["NSApp"])
  {
    c = Keyboard.DesktopAppModelContext(_config, Fins.Model.DEFAULT_MODEL);
    c->config = config;
    c->app = app;
    c->model = this;

    // TODO: fix this properly.
    c->lower_case_link_names = lower_case_link_names;
    c->initialize();

// we defer type registration until after running the migration.
//    if(!all_constants()["__defer_full_startup"])
//      c->register_types();

    return c;
  }
  else
  {

    c = ::get_context(_config, Fins.Model.DEFAULT_MODEL);
    return c;
  }
}

void load_model()
{
  
  ::load_model();
  foreach(Fins.Model.module.get_context_ids();; string id)
  {
    object ctx;

    ctx = Fins.Model.get_context(id);
    if(functionp(ctx->run_upgrade))
      ctx->run_upgrade();

    if(!all_constants()["__defer_full_startup"])
      ctx->register_types();
  }
}
