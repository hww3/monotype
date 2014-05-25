Stdio.File f;

import EError;

mapping code_pos = ([]);

int code_count;
string last_result;
string interface_device;

int isConnected = 0;
int inCommandMode = 0;

int main(int argc, array argv)
{
  populate_cw();

  object rib = ((program)"Ribbon")(argv[1]);

  int len;
  mapping inf = rib->get_info(); 
  array keys = indices(inf);
  foreach(keys;;string k)
    if(sizeof(k) > len) len = sizeof(k);

  foreach(inf; string k; mixed v)
  {
    write("%" + len + "s: %s\n", String.capitalize(replace(k, "_", " ")), (string)v);
  }

  f = find_interface();

  command_mode();

  string version = get_version();
  string status = get_status();

  wx("ATP\n");
  if(expect_result("OK"))
  {
    werror("Error: Punch unit not ready to punch. Please reset and try again.\n");
    exit(1);
  }

  write("\n");
  write("Version: %O\n", version);
  write("Status: %O\n", status);
  write("\n");
  write("Ready to punch. Hit return to begin.\n");
  string r = Stdio.stdin.gets();
  return 0;

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

object find_interface()
{
  object f;
  array x = glob("cu.usbmodem*", get_dir("/dev"));
  werror("candidates: %s\n", String.implode_nicely(x));
  foreach(x||({});; string interface)
  {
    catch(f = Stdio.File("/dev/" + interface, "rw"));

    if(f && check_interface(f)) 
    { 
      interface_device = interface; 
      isConnected = 1; 
      return f; 
    }
  }
  
  throw(Error.Generic("Unable to find interface.\n"));
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

string get_status()
{
  if(!inCommandMode)
    throw(InvalidModeException("Invalid Mode.\n"));
  wx("ATS\n");
  if(expect_result("OK"))
  {
    throw(NotReadyException("Unable to retrieve status. Please reset and try again.\n"));
  }

  string status;
  sscanf(last_result, "OK %s", status);
  return status;
}  	

string get_version()
{
  if(!inCommandMode)
    throw(InvalidModeException("Invalid Mode.\n"));
  wx("ATI\n");
  if(expect_result("OK"))
  {
    throw(NotReadyException("Unable to retreive version. Please reset and try again.\n"));
  }

  string ver;
  sscanf(last_result, "OK %s", ver);
  ver = (ver/" ")[-1];
  return ver;
}

void command_mode()
{
  wx("AT\n");
  if(expect_result("OK")) // if we don't get an OK, we might be in punch mode. try escaping.
  {
    wx("+++++");   
    if(expect_result("OK"))
    {
      inCommandMode = 0;
      throw(InvalidModeException("Unable to enter command mode. Please reset and try again.\n"));
    }
  }

  inCommandMode = 1;
}

int check_interface(object f)
{
  wxf(f, "AT\n");
  if(expect_result(f, "OK")) // if we don't get an OK, we might be in punch mode. try escaping.
  {
    wxf(f, "+++++");   
    if(expect_result(f, "OK"))
    {
      return 0;
    }
  }
  return 1;
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
variant int expect_result(string res)
{
  return expect_result(f, res);
}

// returns 0 if the expected string is received.
variant int expect_result(object f, string res)
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
  return wxf(f, @args);
}

int wxf(object f, mixed ... args)
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
