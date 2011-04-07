inherit Fins.Model.DataModelContext;


#if constant(Public.ObjectiveC)

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

	sql_url = "sqlite://" + combine_path((string)folder, "RibbonGeneratorData.sqlite3");
	werror("**** " + sql_url);
}

#endif
