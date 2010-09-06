756c

  if(config->page_length && !(linesonpage%config->page_length))
  {
	break_page();
  }
  else
    current_line = make_new_line();


.
567a
void break_page()
{
	insert_footer();		
	insert_header();		
}

.
440a
	linesonpage++;
.
414c

	else if(lcdata == "<pagenumber>")
	{
	   		  data_to_set+= ({(string)pagenumber});
	}
    else if(lcdata == "<pagebreak>")
	{
	   		 break_page();
	}
	
.
259c
						string syl = (" "+(wp[0..fp] * "") + ((config->unnatural_word_breaks && config->hyphenate_no_hyphen)?"":"-"));
.
199c
	{
//	  current_line = make_new_line();
	  insert_header();
	}
.
193a
void insert_header()
{
	pagenumber++;
    linesonpage = 1;

	string header_code;
	if(pagenumber%2) header_code = oheader_code;
	else header_code = eheader_code;
	
	current_line = make_new_line();
	
	if(!in_do_header && sizeof(header_code))
	{
		in_do_header = 1;
		current_line->errors += ({"* New Page Begins -"});
		werror("parsing header: %O\n", header_code);
		array _data_to_set = data_to_set;
		data_to_set = ({});
		object parser = Parser.HTML();
		mapping extra = ([]);
		parser->_set_tag_callback(i_parse_tags);
		parser->_set_data_callback(i_parse_data);
		parser->set_extra(extra);

		// feed the data to the parser and have it do its thing.
		parser->finish(header_code);
		data_to_set = _data_to_set;
		in_do_header = 0;
	}
}

void insert_footer()
{
	string footer_code;
	if(pagenumber%2) footer_code = ofooter_code;
	else footer_code = efooter_code;
	
	current_line = make_new_line();
	
	if(!in_do_footer && sizeof(footer_code))
	{
		in_do_footer = 1;
		werror("parsing footer: %O\n", footer_code);
		array _data_to_set = data_to_set;
		data_to_set = ({});
		object parser = Parser.HTML();
		mapping extra = ([]);
		parser->_set_tag_callback(i_parse_tags);
		parser->_set_data_callback(i_parse_data);
		parser->set_extra(extra);

		// feed the data to the parser and have it do its thing.
		parser->finish(footer_code);
		data_to_set = _data_to_set;
		in_do_footer = 0;
	}
}

.
25a
int pagenumber;
int linesonpage;
.
w
q
