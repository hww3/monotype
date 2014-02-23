Stdio.File f;

mapping code_pos = ([]);

int code_count;

int wx(mixed ... args)
{

//  write(">> ");
//  write(@args);
return 0;
//  return f->write(@args);
}
int main(int argc, array argv)
{
  populate_cw();

  object rib = ((program)"Ribbon")(argv[1]);

  werror("header: %O\n", rib->get_info());

//  f = Stdio.File("/dev/cu.usbmodem12341", "rw");
  wx("AT\r\n");
//  werror("<< %O\n", f->read(100, 1));

  wx("ATP\r\n");
//  werror("<< %O\n", f->read(100, 1));

  sleep(5);
  float codetime = time(2); 
  array codes;

  send_footer();
  send_header();
return 0;
  while(codes = rib->get_next_code())
  {
    send_codes(codes);
  }

  codetime = time(2) - codetime;
  werror("code count: %O in %f seconds\n", code_count, codetime);
 return 0;


/*
  write("%b%b%b%b\r\n", 0B11010001, 0B11011001, 0B11010001, 0B11010111);
 write("\n\n");
  wx("%c%c%c%c\r\n", 0B11010001, 0B11011001, 0B11010001, 0B11010111);
  write("%b%b%b%b\r\n", 0B11000001, 0B01000001, 0B00010000, 0B11000001);
  wx("%c%c%c%c\r\n", 0B11000001, 0B01000001, 0B00010000, 0B11000001);
*/
  wx("+++++");
  wx("ATS\r\n");
  string s;
  while(s = f->read(1, 1))
  { 
    write("<< " + s);
  }

  return 0;
}

void send_codes(array codes)
{
  int cw;
  foreach(codes;;string c)
  {
    cw|=code_pos[c];
  }
  code_count++;
  write("%031b\n", cw);
//  f->write("%4c\r\n", cw | (1<<31));
//  werror("<< %O\n", f->read(100, 1));
}

void send_header()
{
  feed_lines(10);  
  send_arrow();
}

void send_footer()
{
  send_arrow();
  feed_lines(10);
}

void send_arrow()
{
  int cw;
  int x = 1;
  int y = 1<<30;

  for(int i = 0;  i<15; i++)
  {
    write("%031b\n", x|y|(1<<31));
    x<<=1;
    y>>=1;
  }

  write("%031b\n", x|(1<<31));
}

void feed_lines(int l)
{
  for(int i = 0; i < l; i++)
    write("%031b\n", 0|(1<<31));
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
