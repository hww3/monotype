dependencies = {
	layers: [
		{
			// This is a specially named layer, literally 'dojo.js'
			// adding dependencies to this layer will include the modules
			// in addition to the standard dojo.js base APIs.
			name: "dojo.js",
			dependencies: [
				"dijit._Widget",
				"dijit._Templated",
				"dijit.form.MatrixEditor",
				"dijit.form.Textarea",
				"dijit.TooltipDialog",
				"dijit.InlineEditBox",
				"dojox.layout.FloatingPane",
				"dojo.fx",
				"dojo.NodeList-fx",
				"dojox.collections.ArrayList",
				"dojox.widget.DialogSimple"
			]
		}
	],

	prefixes: [
		[ "dijit", "../dijit" ],
		[ "dojox", "../dojox" ]
	]
}
