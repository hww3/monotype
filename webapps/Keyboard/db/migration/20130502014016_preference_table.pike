inherit Fins.Util.MigrationTask;
  
constant id = "20130502014016";
constant name="preference_table";

void up()
{
  if(sizeof(context->sql->list_tables("preferences")))
  {
    announce("Preferences table exists from pre-migration install. Skipping.");
    return;
  }
  object tb = get_table_builder("preferences");
  tb->add_field(@tb->ID);
  tb->add_field("user_id", "integer", (["not_null": 1]));
  tb->add_field("name", "string", (["length": 64, "not_null": 1, "default": ""]));
  tb->add_field("type", "integer", (["not_null": 1]));
  tb->add_field("value", "string", (["length": 255, "not_null": 1, "default": ""]));
  tb->go();
}

void down()
{
  drop_table("preferences");
}


