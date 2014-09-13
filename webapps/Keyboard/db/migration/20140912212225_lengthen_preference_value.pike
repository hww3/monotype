inherit Fins.Util.MigrationTask;
  
constant id = "20140912212225";
constant name="lengthen_preference_value";

void up()
{
  change_column("preferences", "value", (["type": "string", "length": 64*1024, "not_null": 1, "default": "", "name": "value"]));  
}

void down()
{
  
}
