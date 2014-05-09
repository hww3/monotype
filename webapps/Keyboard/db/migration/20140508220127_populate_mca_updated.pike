inherit Fins.Util.MigrationTask;
  
constant id = "20140508220127";
constant name="populate_mca_updated";

void up()
{
  context->register_type("Matcasearrangement", Keyboard.DataMappings.Matcasearrangement);
  mixed r = context->find->matcasearrangements_all();
  foreach(r;;object mca)
    mca["updated"] = Calendar.now()->format_http();
}

void down()
{
  // none needed.
}
