inherit Fins.Model.SqlDataModelContext;


#if constant(Public.ObjectiveC) && constant(Public.ObjectiveC.load_bundle)

import Public.ObjectiveC;

void set_url(string url)
{
	object fm = Cocoa.NSFileManager.defaultManager();
	url = "~/Library/Application Support/Monotype Caster Control";
	object folder = Cocoa.NSString.stringWithCString_(url)->stringByExpandingTildeInPath();
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

	url = "sqlite://" + combine_path((string)folder, "RibbonGeneratorData.sqlite3");
	werror("**** " + url);

  run_upgrade();
}

#endif

void run_upgrade()
{
  object s = Sql.Sql(url);
  if(sizeof(s->list_tables("preferences"))) return;

  // ok, we need to create the preferences table.
  werror("creating preferences table.\n");
  s->query(
#"CREATE TABLE preferences (
  id integer primary key,
  user_id integer not null,
  name char(64) NOT NULL default '',
  type integer NOT NULL default 0,
  value char(64) NOT NULL default ''
)"
);
}
