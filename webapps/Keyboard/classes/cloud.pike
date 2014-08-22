#charset utf8

import Fins;

inherit XMLRPCController;

constant __uses_session = 0;

private object sessions = Tools.Mapping.SlidingCache(600);

#define CHECKUSER(X) do{ if(sessions[X]) X = sessions[X]; else throw(Error.Generic("Invalid login.")); }while(0);
 
string login(object id, string user, string password)
{  
  mixed u;
  
  if((u = check_user(user, password)))
  {
    // populate the session with the new user, removing any existing session for the same user.
    string sessionid = search(sessions, u);
    if(sessions[sessionid]) m_delete(sessions, sessionid);
    sessionid = String.string2hex(Crypto.MD5.hash(u["username"] + password + (string)time() + (string)random(100000)));
    sessions[sessionid] = u;
    return sessionid;
  }
  else return 0;
}

array list_mcas(object id, mixed session)
{
  CHECKUSER(session);
  array x = allocate(sizeof(session["mcas"]));
  foreach(session["mcas"]; int i; object mca)
  {
    x[i] = (["id": mca["id"], "name": mca["name"], "updated": mca["updated"]]);
  }
  return x;
}

mapping get_mca(object id, mixed session, int mca_id)
{
  CHECKUSER(session);
  object mca = Fins.Model.find.matcasearrangements_by_id(mca_id);
  if(!mca) return 0;
  return ([ "name": mca["name"], 
            "owner": mca["owner"]["name"], 
            "is_public": mca["is_public"],
            "xml": mca["xml"],
            "updated": mca["updated"]
  ]);  
}

int put_mca(object id, mixed session, string mcaxml, string updated)
{
  CHECKUSER(session);
  
  object mcao = Monotype.load_matcase_string(mcaxml);
  app->save_matcase(mcao, session, -1, Calendar.dwim_time(updated));
  return 1;  
}


protected int|object check_user(string user, string password)
{
  array r = Fins.Model.find.users((["username": user,
     "is_active": 1]));      
  if(!r || !sizeof(r)) 
    return 0;
    
  if(Crypto.verify_crypt_md5(password, r[0]["password"])) 
    return r[0];
  else 
    return 0;
}