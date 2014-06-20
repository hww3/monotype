inherit Fins.Util.MigrationTask;
  
constant id = "20140617224022";
constant name="create_font_schemes";

void up()
{
  object tb = get_table_builder("font_schemes");
  tb->add_field("id", "integer", (["primary_key": 1, "auto_increment": 1]));
  tb->add_field("owner_id", "integer", (["not_null": 1]));
  tb->add_field("name", "string", (["length": 64, "not_null": 1]));
  tb->add_field("definition", "binary_string", (["length": 1024*32]));
  tb->add_field("is_public", "integer", (["not_null": 1]));
  tb->add_field("updated", "string");
  tb->go();
}

void down()
{
  drop_table("font_schemes");  
}
