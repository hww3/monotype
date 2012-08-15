inherit Fins.FinsModel;

object get_context(mapping config)
{
	// are we running in a desktop mode?
	if(all_constants()["NSApp"])
		return Keyboard.DesktopAppModelContext(config, Fins.Model.DEFAULT_MODEL);
	else
		return ::get_context(config, Fins.Model.DEFAULT_MODEL);
}
