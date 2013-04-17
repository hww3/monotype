inherit Fins.Util.MigrationTask;
  
constant id = "20130417010204";
constant name="create_ribbon_configs";

void up()
{
  object tb = get_table_builder("ribbon_configs");
  tb->add_field("id", "integer", (["primary_key": 1, "auto_increment": 1]));
  tb->add_field("user_id", "integer", (["not_null": 1]));
  tb->add_field("name", "string", (["length": 64, "not_null": 1]));
  tb->add_field("definition", "binary_string", (["length": 1024*32]));
  tb->add_field("updated", "timestamp");
  tb->go();
}

void down()
{
  drop_table("ribbon_configs");  
}
