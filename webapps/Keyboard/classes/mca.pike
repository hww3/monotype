import Fins;

inherit DocController;

   array cols15 = ({ /* 15 elements */
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
                "L", "M", "N", "O"
            });

   array cols17 = ({ /* 17 elements */
                "NI", "NL", "A", "B", "C", "D", "E", "F", "G", "H", "I", 
                "J", "K", "L", "M", "N", "O"
            });

  array rows15 = ({ /* 15 elements */
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
            });

  array rows16 = ({ /* 16 elements */
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
            });

/*
  write("<table><th></th>\n");
  foreach(cols;;string c)
  {  
    write("<th>" + c + "</th>");
  }
  foreach(rows;;string r)
  {
     write("<tr><th>" + r + "</th>");
     foreach(cols;; int c)
       write("<td><input size=\"2\" type=\"text\" name=" + r + c + "\"></td>");
     write("</tr>\n");
  }
*/

public void index(Request id, Response response, Template.View view, mixed args)
{
  array m = map(glob("*.xml", get_dir(app->config["locations"]["matcases"]) || ({})), lambda(string s){return (s/".xml")[0];});


  view->add("mcas", m);
}

public void new(Request id, Response response, Template.View view, mixed args)
{
	
}

public void edit(Request id, Response response, Template.View view, mixed args)
{
  object mca;

  if(!sizeof(args))
  {
	response->set_data("You must provide a mat case layout to edit.");
  }

werror("args:%O, %O\n", getcwd(),combine_path(app->config["locations"]["matcases"], args[0]));
  if(!mca)
    mca = Monotype.load_matcase(combine_path(getcwd(), app->config["locations"]["matcases"], args[0]));

  view->add("mca", mca);
  view->add("rows", rows15);   
  view->add("cols", cols15);
}

