inherit Fins.Util.MigrationTask;
  
constant id = "20140508002204";
constant name="add_mca_timestamp";

void up()
{
  add_column("matcasearrangements", "updated", (["type": "string"]));  
}

void down()
{
  drop_column("matcasearrangements", "updated");
}
