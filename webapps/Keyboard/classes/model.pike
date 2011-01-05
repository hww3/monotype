inherit Fins.FinsModel;

object get_context(mapping config)
{
	// are we running in a desktop mode?
	if(all_constants()["NSApp"])
		return Keyboard.DesktopAppModelContext();
	else
		return ::get_context(config);
}