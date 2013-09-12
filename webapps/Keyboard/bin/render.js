var page = require('webpage').create(),
    system = require('system'),
    address, output, size;

if (system.args.length < 3 || system.args.length > 5) {
    console.log('Usage: rasterize.js URL filename [paperwidth*paperheight|paperformat] [zoom]');
    console.log('  paper (pdf output) examples: "5in*7.5in", "10cm*20cm", "A4", "Letter"');
    phantom.exit(1);
} else {
    address = system.args[1];
    output = system.args[2];
    page.viewportSize = { width: 600, height: 600 };

  page.onResourceRequested = function (req, a) {
        console.log('requested: ' + JSON.stringify(req, undefined, 4));
       if(!(req.url.indexOf('.html') > 0))
      {
         console.log('   to: ' + req.url.replace("file:///", "file://Keyboard/"));
         a.changeUrl(req.url.replace("file:///", "./Keyboard/"));
      }
    };

    page.onResourceReceived = function (res) {
        console.log('received: ' + JSON.stringify(res, undefined, 4));
    };

    if (system.args.length > 3 && system.args[2].substr(-4) === ".pdf") {
        size = system.args[3].split('*');
        page.paperSize = size.length === 2 ? { width: size[0], height: size[1], margin: '0px' }
                                           : { format: system.args[3], orientation: 'portrait', margin: '0.9cm' };
    }
    if (system.args.length > 4) {
        page.zoomFactor = system.args[4];
    }
    page.open(address, function (status) {
        if (status !== 'success') {
            console.log('Unable to load the address!');
            phantom.exit();
        } else {
            window.setTimeout(function () {
                page.render(output);
                phantom.exit();
            }, 200);
        }
    });
}
