Stdio.File f;

import EError;

mapping code_pos = ([]);
ADT.Queue codes_on_deck = ADT.Queue();

function status_callback;
function version_callback;

int code_count;
string last_result;
string read_data = "";
string outgoing_data = "";
string interface_device;
string _interface_status;
string _interface_version;

mixed status_callout_id;

object ui;

int isConnected = 0;
int inCommandMode = 0;
int inPunchMode = 0;
int started = 0;

string `->interface_status()
{
  return _interface_status;
}

string `->interface_status=(string x)
{
  _interface_status = x;
  if(status_callback)
    status_callback(x);
}

string `->interface_version()
{
  //werror("interface version = %O", _interface_version);
  
  return _interface_version;
}

string `->interface_version=(string x)
{
  _interface_version = x;
  //werror("interface version = %O", _interface_version);
  if(version_callback)
    version_callback(x);
}

void connect(function success, function failure)
{
  call_out(do_connect, 0.0, success, failure);
}

void do_connect(function success, function failure)
{
  mixed err;
  
  err = catch 
  {
    f = find_interface();
  };
  
  if(err)
  {
    failure("No interface found.\n");
    return;
  }
   
  err = catch 
  { 
    interface_status = get_status(); 
    interface_version = get_version();
  };
  
  if(err)
  {
    err = Error.mkerror(err);
    werror(master()->describe_backtrace(err->backtrace())); 
    failure("Interface not ready.\n");
    if(f) f->close();
    f = 0;
    return;
  }

  success(interface_device);

}

void new_ribbon(object ribbon, int include_header)
{
  codes_on_deck = ADT.Queue();
  code_count = 0;
  if(include_header)
  {
    send_header(ribbon->get_info());
  }
  
  codes_on_deck->write(ribbon);
  
  if(include_header)
    send_footer();  
}

void start()
{  
  started = 1;  
  punch_mode();
}

// non-blocking punch mode
void punch_mode()
{
  //werror("Punch Mode starting\n");
  remove_call_out(status_callout_id);
  status_callout_id = 0;
  
  wx("ATP\n");
  if(expect_result("OK"))
  {
    throw(Error.Generic("Punch unit not ready to punch. Please reset and try again.\n"));
  }
  if(f)
  {
    f->set_non_blocking();
    f->set_read_callback(nb_punch_read);
    f->set_write_callback(nb_punch_write);
  }
  inCommandMode = 0;
  inPunchMode = 1;
  send_next_code();
  if(!f)
    call_out(fake_read, 0.1);
}

void fake_read()
{
 // werror("fake_read:\n");
  if(inPunchMode)
  {
    nb_punch_read(1, "OKP\n");
  //  werror("setting call out\n");
    call_out(fake_read, 0.1);
  }  
}

int nb_punch_read(mixed id, string d)
{
  if(d)
  {
    read_data += d;   
    got_data();
  }
}

void got_data()
{
  // have we read a complete response?
  int n = search(read_data, "\n");
  if(n != -1)
  {
    // allocate the response and remove it from the input buffer.
    string resp = read_data[0..n];
    if((n+1) == sizeof(read_data))
      read_data = "";
    else 
      read_data = read_data[(n+1)..];

    resp = String.trim_all_whites(resp);
          
    if(inPunchMode)
    {
      if(resp != "OKP")
      {
        last_result = resp;
        //werror(" NOT OK\n");
        ui->fault(resp);
        started = 0;
        command_mode();
        
        catch(interface_status = get_status());
        if(interface_status)
          ui->setInterfaceStatus(interface_status);
      }
      else
      {
        //werror("OK\n");
        // we don't remove codes from the stream until confirmed,
        // that way we can continue from the same position after a fault is cleared.
        if(confirm_current_code() && started)
          send_next_code();
      }
    }
  }
}

int confirm_current_code()
{
  if(!codes_on_deck->is_empty())
  {
    mixed c = codes_on_deck->peek();
    if(!objectp(c))
      codes_on_deck->read();
    else
    {
      c->get_next_code(); // consume the code.
      if(!c->peek_next_code()) // if that was the last code from the ribbon, remove it from the queue.
        codes_on_deck->read();
    }
    return !codes_on_deck->is_empty();
  }
  else // nothing left to send
  {
    ui->punchEnded();
    command_mode();
    return 0;
  }
}

void send_next_code()
{
  if(!codes_on_deck->is_empty())
  {
    mixed c = codes_on_deck->peek();
    if(objectp(c))
      c = c->peek_next_code();
    send_codes(c);  
  }
  else
  {
    throw(Error.Generic("shouldn't have gotten here.\n"));
  }
  
}

int nb_punch_write(mixed id)
{
  if(sizeof(outgoing_data))
  {
    int r;
    
    if(f)
      r = f->write(outgoing_data);
      
    if(r == sizeof(outgoing_data))
      outgoing_data = "";
    else
      outgoing_data = outgoing_data[r..];
  }
}

void stop()
{
  started = 0;
  // allow any work in flight to complete.
  if(f)
  {
    string s;
    f->set_blocking();
    if(s = f->read(1000, 1))
      nb_punch_read(1, s);
  } 
  else
  {
    nb_punch_read(1, "OKP\n");
  }
  command_mode();
  catch(interface_status = get_status());
  
  if(interface_status)
    ui->setInterfaceStatus(interface_status);
}

static void create()
{
  populate_cw();  
}

int main(int argc, array argv)
{
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
  send_codes(rib);
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
    mixed err;
    err = catch(f = Stdio.File("/dev/" + interface, "rw"));
    
    if(err)
    {
      werror(interface + " (connect): " + err->message());
      werror(master()->describe_backtrace(err->backtrace())); 
      continue;
    } 
    
    if(err = catch(command_mode(f)))
    {
      werror(interface + ": " + err->message());
      werror(master()->describe_backtrace(err->backtrace())); 
      continue;
    } 
    else
    {
      werror("connect success on " + interface + "\n");
      interface_device = interface; 
      isConnected = 1; 
      return f; 
    }
  }
  
  throw(Error.Generic("Unable to find interface.\n"));
}

void send_codes(array|object codes)
{
  int cw;
//  werror("codes: %O\n", codes);
  if(intp(codes))
  {
    send_code(codes | (1<<31));
    return;
  }
  foreach(codes - ({""});;string c)
  {
    cw|=code_pos[c];
//    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
  }
  code_count++;
  send_code(cw | (1<<31));
}

string get_status()
{
  if(!inCommandMode)
    throw(InvalidModeException("Invalid Mode.\n"));
  wx("ATS\n");
  if(expect_result("OK") && !has_prefix(last_result, "ERROR"))
  {
    throw(NotReadyException("Unable to retrieve status. Please reset and try again.\n"));
  }
  else if(has_prefix(last_result, "ERROR"))
  {
    string status;
    sscanf(last_result, "ERROR %s", status);
    return status;    
  }
  else
  {
    string status;
    sscanf(last_result, "OK %s", status);
    return status;
  }
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
  sscanf(last_result, "OK %s\n", ver);
  ver = (ver/" ")[-1];
  return ver;
}

void command_mode(object|void i)
{
//  werror("command_mode: %O\n", i);
  inPunchMode = 0;
  do_command_mode(i || f);
}

void do_command_mode(object|void f)
{
  if(f)
    f->set_blocking();
    
  wxf(f, "AT\n");
//  werror("waiting.\n");
  mixed err = catch
  {
  if(expect_result("OK", f)) // if we don't get an OK, we might be in punch mode. try escaping.
  {
    wxf(f, "+++++");   
    if(expect_result("OK", f))
    {
      inCommandMode = 0;
      throw(InvalidModeException("Unable to enter command mode. Please reset and try again.\n"));
    }
  }
};
if(err)
{
  err = Error.mkerror(err);
  werror(err->message());
  ui->fault(err->message());
}
else
{
//  werror("inCommandMode\n");
  inCommandMode = 1;
  status_callout_id = call_out(bg_check_status, 2.0);
}
}

void bg_check_status()
{
  mixed err;
  if(err = catch(interface_status = get_status()))
  {
    err = Error.mkerror(err);
    ui->fault(err->message());
    ui->disconnect();
    return;
  }
//  werror("status: %O\n", interface_status);
  status_callout_id = call_out(bg_check_status, 1.0);
}

int check_interface(object f)
{
  wxf(f, "AT\n");
  if(expect_result("OK", f)) // if we don't get an OK, we might be in punch mode. try escaping.
  {
    wxf(f, "+++++");   
    if(expect_result("OK", f))
    {
      return 0;
    }
  }
  wxf(f, "ATI\n");
  if(expect_result("OK Monotype", f)) // if we don't get an OK, we might be in punch mode. try escaping.
  {
    wxf(f, "+++++");   
    if(expect_result("OK", f))
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
     codes_on_deck->write(c|(1<<31));
//     if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
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
    codes_on_deck->write(x|y|(1<<31));
//    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
    x>>=1;
    y<<=1;
  }

}

void feed_lines(int l)
{
  for(int i = 0; i < l; i++)
  {
    codes_on_deck->write(0|(1<<31));
//    if(expect_result("OKP")){ werror("Punch fault.\n"); exit(1); };
  }
}

// returns 0 if the expected string is received.
variant int expect_result(string res, object f)
{
  if(!f) return 0;
//  werror("Expecting " + res + " on %O\n", f);
  string got = "";
  string g;
  do
  { 
  //  werror("Reading\n");
   // if(!sizeof(got) && f->peek(0.1) == 0) return 1;
    
    g = f->read(100,1);
    //werror("g = %O\n", g);
    if(g)
      got += g;
  } while(g!=0 && g!="" && search(g, "\n") ==-1);
  
  //werror("<< %O\n", got);
  if(got)
    last_result = got;
    
  return !has_prefix(got,res);
}

// returns 0 if the expected string is received.
variant int expect_result(string res)
{
//  werror("Expecting " + res + "\n");
  return expect_result(res, f);
}

int send_code(int code)
{
  write(code + replace(sprintf(" >> %032b =>", code), ({"0", "1"}), ({" ", "."})));
//return 0;
  string d = sprintf("%4c\r\n", code);
  if(f)
  {
    int c = f->write(d);
    if(c != sizeof(d))
    {
      outgoing_data += d[c..];
    }
  }
}

int wx(mixed ... args)
{
  return wxf(f, @args);
}

int wxf(object f, mixed ... args)
{
//  write("%O >> ", f);
//  write(@args);
  
  if(f)
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
