
dojo.provide("dijit.form.MatrixEditor");
dojo.require("dojo._base.html");
dojo.require("dijit.form._FormWidget");
dojo.require("dijit.form.NumberTextBox");
dojo.require("dijit.form.Button");
dojo.require("dijit.form.CheckBox");
dojo.require("dijit.form.FilteringSelect");

dojo.declare(
	"dijit.form.MatrixEditor",
	[dijit._Widget, dijit._Templated],
	{
		trim: false,
		uppercase: false,
		lowercase: false,
		propercase: false,
		maxLength: "10",

		row: 0,
		column: 0,
		
		default_set_width: 0,
		default_series: "",
		default_style: "",
		default_size: 0,
		
		origNode: 0,
		srcId: "he",
		name: "matrixeditor",
		type: "med",
		
		_activator: 0,
		_set_width: 0,
		_character: 0,
		_style: 0,
		_series: 0,
		_size: 0,
		
		onCancel: function(){},
		onSave: function(){},

		widgetsInTemplate: true,

		sorteditordiv : 0,
		sortradio : 0,
		spaceradio : 0,
		justradio : 0,
		emptyradio : 0,

    		getDisplayedValue: function(){
    			//	summary:
    			//		Returns the formatted value that the user sees in the textbox, which may be different
    			//		from the serialized value that's actually sent to the server (see dijit.form.ValidationTextBox.serialize)
    //			return this.filter(this.textbox.value);
    		},
		
    		setValue: function(value, /*Boolean?*/ priorityChange, /*String?*/ formattedValue){
    			//	summary: 
    			//		Sets the value of the widget to "value" which can be of
    			//		any type as determined by the widget.
    			//
    			//	value:
    			//		The visual element value is also set to a corresponding,
    			//		but not necessarily the same, value.
    			//
    			//	formattedValue:
    			//		If specified, used to set the visual element value,
    			//		otherwise a computed visual value is used.
    			//
    			//	priorityChange:
    			//		If true, an onChange event is fired immediately instead of 
    			//		waiting for the next blur event.

    			var filteredValue = this.filter(value);
    			if((((typeof filteredValue == typeof value) && (value !== undefined/*#5317*/)) || (value === null/*#5329*/)) && (formattedValue == null || formattedValue == undefined)){
    				formattedValue = this.format(filteredValue, this.constraints);
    			}
    //			if(formattedValue != null && formattedValue != undefined){
    //				this.textbox.value = formattedValue;
    //			}
    
   // 			dijit.form.MatrixEditor.superclass.setValue.call(this, filteredValue, priorityChange);
    		},

		
		format: function(/* String */ value, /* Object */ constraints){
			//	summary:
			//		Replacable function to convert a value to a properly formatted string
			return ((value == null || value == undefined) ? "" : (value.toString ? value.toString() : value));
		},

		parse: function(/* String */ value, /* Object */ constraints){
			//	summary:
			//		Replacable function to convert a formatted string to a value
			return value;
		},
		
				_setBlurValue: function(){
    			this.setValue(this.getValue(), (this.isValid ? this.isValid() : true));
    		},

    		_onBlur: function(){
    			this._setBlurValue();
    //			this.inherited(arguments);
    		},
		
		filter: function(val){
			//	summary:
			//		Apply specified filters to textbox value
			if(val === null || val === undefined){ return ""; }
			else if(typeof val != "string"){ return val; }
			if(this.trim){
				val = dojo.trim(val);
			}
			if(this.uppercase){
				val = val.toUpperCase();
			}
			if(this.lowercase){
				val = val.toLowerCase();
			}
			if(this.propercase){
				val = val.replace(/[^\s]+/g, function(word){
					return word.substring(0,1).toUpperCase() + word.substring(1);
				});
			}
			return val;
		},

		
		
		setNewVal: function()
		{
//		  alerty();
			//alert("this.origNode:" + this.origNode.innerHTML);
			if(this._mat_type == "FS")
			  this.origNode.innerHTML="<img src=\"/static/images/fs.png\">";
			else if(this._mat_type == "JS")
			  this.origNode.innerHTML="<img src=\"/static/images/js.png\">";
			else if(this._mat_type == "SORT")
			{
			  var q = this._character;
			  if(this._style == "B")
				q = "<b>" + q + "</b>";
			  if(this._style == "U")
				q = "<u>" + q + "</u>";
			  if(this._style == "I")
				q = "<i>" + q + "</I>";
			  if(this._style == "S")
				q = "<tt>" + q + "</tt>";
			  this.origNode.innerHTML='<div class="dojoDndItem" dndtype="X" id="' + this.origNode.id.replace('dnd-', '') + '">' +q + "</div>";
			}
			else this.origNode.innerHTML="";
			this.origNode.style.color = 'blue';
			//alert("default: " + (this.default_set_width) + " this: "  + this._set_width);
			if(this.default_set_width != this._set_width)
			{
				this.origNode.style.background= 'yellow';
			}
			else
			{
				this.origNode.style.background= '';
				
			}
		},
		
				postCreate: function(){
    			// setting the value here is needed since value="" in the template causes "undefined"
    			// and setting in the DOM (instead of the JS object) helps with form reset actions
    //			this.textbox.attr("value", this.getDisplayedValue());
    			// this.inherited(arguments);

    			this._setup();
//    			dijit.form.MatrixEditor.superclass.postCreate.call();
    		},

    
				_setup: function() {
				  //alert("setup!");
    			this.origNode = dojo.byId(this.srcId);
    			//alert("origNode: " + this.srcId);

    			var issort;
    			// first, we find out if we're a space or a sort.
    			var matdef = this.mat;
    			
//  			alerta("matdev: " + matdef);
    			if(!matdef || !matdef.childNodes || matdef.childNodes.length!=1) 
    			{ 
    				this._setIsEmpty();
    				this.lowSetStyle(this.default_style);
    				this._set_width = this.default_set_width;
    				this._series = this.default_series;
    				this._size = this.default_size;
    				//alert("default set width: " + this.default_set_width);
    				return;
    			}

    			matdef = matdef.childNodes[0];

    			var att = matdef.attributes.getNamedItem("activator");
    			if(att)
    				this._activator = att.value;
    			att = matdef.attributes.getNamedItem("set_width");
    			if(att)
    				this._set_width = att.value;
    			else
    				this._set_width = this.default_set_width;

    			att = matdef.attributes.getNamedItem("character");
    			if(att)
    				this._character = att.value;

    			att = matdef.attributes.getNamedItem("weight");
    //			if(att) alert("style: " +att.value);

    			if(att)
    			{
    				this.lowSetStyle(att.value); 
    			}

    			att = matdef.attributes.getNamedItem("series");
    			if(att)
    				this._series = att.value;
    			else
    				this._series = this.default_series;

    			att = matdef.attributes.getNamedItem("size");
    			if(att)
    				this._size = att.value; 
    			else
    				this._size = this.default_size;

    			att = matdef.attributes.getNamedItem("space");
    //			alert("Whee "  + att);
    			if(att && att.value == "justifying")
    			{
    //				alert("JS");
    			  this._setIsJS();
    			}
    			else if(att && att.value == "fixed")
    			  this._setIsFS();
    			else
    			  this._setIsSort();
    		},
    
		
		_onDoCancel: function()
		{
			this.onCancel(this);
			dijit.popup.close(this.popup); 
//			alewr();
			this.popup.destroyRecursive(true);
		},
		
		_onDoSave: function()
		{
			this.onSave(this);
			dijit.popup.close(this.popup); 
      //			alewr();
			this.popup.destroyRecursive(true);
		},
		
				_onClickSpaceRadio: function()
				{
					if(this.sorteditordiv)
					{
						this.sorteditordiv.style.display='none';
						this._mat_type = "FS";
					}
				},

				_onClickEmptyRadio: function()
				{
		//			alert("empty");
					if(this.sorteditordiv)
					{
						this.sorteditordiv.style.display='none';
						this._mat_type = "";
					}
				},

				_onClickJustRadio: function()
				{
					if(this.sorteditordiv)
					{
						this.sorteditordiv.style.display='none';
						this._mat_type = "JS";
					}
				},
				_onClickSortRadio: function()
				{
					if(this.sorteditordiv)
					{
						this.sorteditordiv.style.display='';
						this._mat_type = "SORT";
						this.low_set_is_sort();
					}
				},
		
		
				_mat_type : "SORT",


				_setIsJS: function() {
					this.justradio._clicked();// = true;
					this._onClickJustRadio();
					this._mat_type = "JS";
				},

				_setIsFS: function() {
					this.spaceradio._clicked();// = true;
					this._onClickSpaceRadio();
					this._mat_type = "FS";
				},

				_setIsEmpty: function() {
					this.emptyradio._clicked();// = true;
					this._onClickEmptyRadio();
					this._mat_type = "";
				},

				_setIsSort: function() {
					this.sortradio._clicked();// = true;
					this._onClickSortRadio();
					this.low_set_is_sort();
				},

				low_set_is_sort: function() {
					this.actbox.setValue(this._activator||"");
					this.setbox.setValue(this._set_width);
					this.charbox.setValue(this._character||"");
					this._mat_type = "SORT";
				},

		onCancel: function(){},
		
				setChar: function() {
					this._character = this.charbox.attr('value');
					if(this.actbox.getValue() == "") this.actbox.setValue(this._character);
				},

				setAct: function() {
					this._activator = this.actbox.getValue();
				},

				setSet: function() {
					this._set_width = this.setbox.getValue();
				},

				setStyle: function()
				{
					var s = this.stylebox.attr("value");
		//alert("s: " + s);
						if(s == "Roman")
							this._style = "R";
						else if(s == "Italic")
							this._style = "I";
						else if(s == "Bold")
							this._style = "B";
						else if(s == "SmallCap")
							this._style = "S";
						else if(s == "Underline")
							this._style = "U";

				},

				lowSetStyle: function(s) {
					//alert("lowSetStyle: " + s);
					this._style = s;			
					if(!s || s == "" || s == "R")
						s = "Roman";
					else if(s == "I")
						s = "Italic";
					else if(s == "S")
						s = "SmallCap";
					else if(s == "B")
						s = "Bold";
					else if(s == "U")
						s = "Underline";

		//alert("setting style to " + s );

					this.stylebox.setValue(s);
				},

				displayValue: function(){
					alert(this.getValue());
				},

				getValue: function(){
					return this.lowGetValue();
				},

				lowGetValue: function() {
					if(this._mat_type == "SORT")
					{
						var series = this._series;
						var size = this._size;
						var style = this._style;
						var character = this.encode(this._character);
						var activator = this.encode(this._activator);
						var set_width = this._set_width;

						return "<matrix series=\"" + series + "\" size=\"" + size + "\" weight=\"" + style + "\" character=\"" + character + "\" activator=\"" + activator + "\" set_width=\"" + set_width + "\"/>";
					}
					else if(this._mat_type == "FS")
					{
						return "<matrix space=\"fixed\" set_width=\"" + this.default_set_width + "\"/>";
					}
					else if(this._mat_type == "JS")
					{
						return "<matrix space=\"justifying\" set_width=\"" + this.default_set_width + "\"/>";
					}
					else return "";
				},

				encode: function(text)
		                {
		                  var textneu = text.replace(/%/,"%25");
				  textneu = textneu.replace(/&/,"%26amp;");
				  textneu = textneu.replace(/</,"%26lt;");
				  textneu = textneu.replace(/>/,"%26gt;");
				  return(textneu);
		                },
		
		
		templateString:
			"<div>" +
			
			"<table width=\"100%\">" + 
			"<tr><td colspan='2'>Col: <b>${column}</b> Row: <b>${row}</b> Default Set: <b>${default_set_width}</b></td></tr>" + 
			"<tr><td><input dojoType=\"dijit.form.RadioButton\" dojoAttachEvent='onClick:_onClickJustRadio' type=\"radio\" dojoAttachPoint='justradio' name=\"type${name}\" value=\"just\"></td><td width=\"90%\"> Justifying Space <td/></tr>\n" + 
			"<tr><td><input dojoType=\"dijit.form.RadioButton\" dojoAttachEvent='onClick:_onClickSpaceRadio' type=\"radio\" dojoAttachPoint='spaceradio' name=\"type${name}\" value=\"space\"></td><td width=\"90%\"> Fixed Space <td/></tr>\n" + 
			"<tr><td><input dojoType=\"dijit.form.RadioButton\" dojoAttachEvent='onClick:_onClickSortRadio' type=\"radio\" dojoAttachPoint='sortradio' name=\"type${name}\" value=\"sort\"></td><td width=\"90	%\"> Sort </td></tr>\n" + 
			"<tr><td><input dojoType=\"dijit.form.RadioButton\" dojoAttachEvent='onClick:_onClickEmptyRadio' type=\"radio\" dojoAttachPoint='emptyradio' name=\"type${name}\" value=\"sort\"></td><td width=\"90	%\"> Empty </td></tr>\n" + 

			"<tr><td colspan=\"2\">" +
			"<div style=\"display: none;\" dojoAttachPoint=\"sorteditordiv\">" +

			"<table>" +
			"<tr><td>Sort: </td><td>" +
			"<input style=\"width:40px\" maxLength=\"5\" required=\"true\" dojoType=\"dijit.form.ValidationTextBox\" dojoAttachPoint='charbox,focusNode' name=\"char${name}\"\n\tdojoAttachEvent='onChange:setChar'\n\tautocomplete=\"off\" type=\"string\"\n\t/>" + 
			" <select style=\"width:120px\" dojoType=\"dijit.form.FilteringSelect\" hasDownArrow=\"true\" autoComplete=\"false\" dojoAttachEvent='onChange:setStyle' dojoAttachPoint='stylebox'>"+
			"<option value='Roman'>Roman</option><option value='Underline'>Underline</option><option value='Italic'>Italic</option><option value='Bold'>Bold</option><option value='SmallCap'>SmallCap</option></select>" +
			"</td></tr><tr><td>" + 
			"Activator Key: </td><td>" +
			"<input style=\"width:40px\" maxLength=\"5\" required=\"true\" dojoType=\"dijit.form.ValidationTextBox\" dojoAttachPoint='actbox,focusNode' name=\"act${name}\"\n\tdojoAttachEvent='onChange:setAct'\n\tautocomplete=\"off\" type=\"${type}\"\n\t/>" + 
			"</td></tr><tr><td>Unit Width: </td><td>" +
			"<input style=\"width:40px\" maxLength=\"5\" required=\"true\" dojoType=\"dijit.form.NumberTextBox\" dojoAttachPoint='setbox' constraints=\"{min: 3, max: 21}\" name=\"set${name}\"\n\tdojoAttachEvent='onChange:setSet'\n\tautocomplete=\"off\" type=\"${type}\"\n\t/>" + 
			"</td></tr></table>" +	

			"</div>\n" +
			"</td></tr>\n" +

			"<tr><td></td><td align=\"right\"><button dojoType=\"dijit.form.Button\" value='Cancel' dojoAttachEvent='onClick:_onDoCancel'>Cancel</button>" +
			"<button dojoType=\"dijit.form.Button\" value='Save' dojoAttachEvent='onClick:_onDoSave'>OK</button></td></tr>\n" +
			"</table>" +
			
			 
			"</div>",
		baseClass: "dijitTextBox",

		setbox: 0,
		stylebox: 0,
		charbox: 0,
		actbox: 0
	}	
);
