Stdio.File f;

mapping code_pos = ([]);

int code_count;
string last_result;

int main(int argc, array argv)
{
  populate_cw();

  object rib = ((program)"Ribbon")(argv[1]);

  werror("header: %O\n", rib->get_info());

  f = Stdio.File("/dev/cu.usbmodem12341", "rw");
//f = Stdio.stdout;
//  send_header(rib->get_info());

  wx("AT\n");
  if(expect_result("OK"))
  {
    wx("+++++");   
    if(expect_result("OK"))
    {
      werror("Error: Punch interface out of sync. Please reset and try again.\n");
      exit(1);
    }
  }
  wx("ATS\n");
  if(expect_result("OK"))
  {
    werror("Error: Punch unit not ready. Please reset and try again.\n");
    exit(1);
  }

  wx("ATI\n");
  if(expect_result("OK"))
  {
    werror("Error: Punch unit not ready to punch. Please reset and try again.\n");
    exit(1);
  }
  
  wx("ATS\n");
  if(expect_result("OK"))
  {
    werror("Error: Punch unit not ready to punch. Please reset and try again.\n");
    exit(1);
  }
  
  wx("ATP\n");
  if(expect_result("OK"))
  {
    werror("Error: Punch unit not ready to punch. Please reset and try again.\n");
    exit(1);
  }

  sleep(5);
  float codetime = time(2); 
  array codes;

  send_header(rib->get_info());
//return 0;
  while(codes = rib->get_next_code())
  {
    send_codes(codes);
  }
  send_footer();


  codetime = time(2) - codetime;
  werror("code count: %O in %f seconds\n", code_count, codetime);

  wx("+++++");
  expect_result("OK");
  wx("ATS\n");
  expect_result("OK");

  f->close();
  return 0;
}

void send_codes(array codes)
{
  int cw;
  foreach(codes;;string c)
  {
    cw|=code_pos[c];
    code_count++;
    send_code(cw | (1<<31));
    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
  }
}

void send_header(mapping info)
{

  feed_lines(10);  
  send_arrow();
  feed_lines(10);
  object ch = (object)("char");
  array codes = ch->gen_chars((string)info->name, (string)info->face, (string)info->wedge + " " + (string)info->set);
  foreach(codes;;int c)
  {
     send_code(c|(1<<31));
     if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
  }
  feed_lines(10);
  send_arrow();
  feed_lines(10);
}

void send_footer()
{
  feed_lines(12);
  send_arrow();
}

void send_arrow()
{
  int cw;
  int x = 1<<15;
  int y = 1<<15;

  for(int i = 0;  i<16; i++)
  {
    send_code(x|y|(1<<31));
    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
    x>>=1;
    y<<=1;
  }

}

void feed_lines(int l)
{
  for(int i = 0; i < l; i++)
  {
    send_code(0|(1<<31));
    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
  }
}


// returns 0 if the expected string is received.
int expect_result(string res)
{
  string got = f->read(100,1);
  werror("<< %O\n", got);
  if(got)
    last_result = got;
  return !has_prefix(got,res);
}

int send_code(int code)
{
  write(replace(sprintf(">> %032b\n", code), ({"0", "1"}), ({" ", "."})));
//return 0;
  return f->write("%4c\r\n", code);
}

int wx(mixed ... args)
{
  write(">> ");
  write(@args);
  return f->write(@args);
}

void populate_cw()
{
  array pos = ({"N", "M", "L", "K","J", "I", "H", "G", "F", "S", "E", "D", "0075", "C", "B", "A", 
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "0005"});
  int i = 1<<30;
  foreach(pos;;string p)
  {
    code_pos[p] = i;
    write("%5s %031b\n", p, i);
    i >>=1;
  }
}
