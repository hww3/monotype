inherit Fins.Model.SqlDataModelContext;


#if constant(Public.ObjectiveC) && constant(Public.ObjectiveC.load_bundle)

import Public.ObjectiveC;

void set_url(string _url)
{
	object fm = Cocoa.NSFileManager.defaultManager();
	_url = "~/Library/Application Support/Monotype Caster Control";
	object folder = Cocoa.NSString.stringWithCString_(_url)->stringByExpandingTildeInPath();
werror("**** checking path...\n");
werror("**** " + (string)folder  + "\n");
	if(!fm->fileExistsAtPath_(folder))
	{
		fm->createDirectoryAtPath_attributes_(folder, ([]));
	}
	if(!fm->fileExistsAtPath_((string)folder + "/RibbonGeneratorData.sqlite3"))
	{
		fm->copyPath_toPath_handler_(combine_path(getcwd(), "Keyboard/config/Keyboard_desktop.sqlite3"), 
			combine_path((string)folder, "RibbonGeneratorData.sqlite3"), 0);
	}

	_url = "sqlite://" + combine_path((string)folder, "RibbonGeneratorData.sqlite3");
	werror("**** " + _url);
        ::set_url(_url);
}

#endif

void run_upgrade()
{
  array run_migrations = ({});
  int dir = Fins.Util.MigrationTask.UP;

  object migrator = Fins.Util.Migrator(app);

  array migrations = migrator->get_migrations(dir);

  if(sizeof(run_migrations))
  {
    foreach(run_migrations;; string m)
    {
       foreach(migrations; int x; object mc)
        if(mc->name != m)
          migrations[x] = 0;
    }
  }

  migrations -= ({0});

  if(dir == Fins.Util.MigrationTask.UP)
    migrator->announce("Applying migrations: ");
  else
  migrator->announce("Reverting migrations: ");
  migrator->write_func("%{" + (" "*3) + "- %s\n%}", migrations->name);


  foreach(migrations;; object m)
  {
    m->run(dir);
  }
}
