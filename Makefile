PUBLIC_OBJECTIVEC=/Users/hww3/Public_ObjectiveC
FINS_REPO="http://hg.welliver.org/"
RIBBON_GENERATOR=RibbonGenerator
CASTER_CONTROL=Caster
#all: stub framework fins webapp

all: ribbongenerator castercontrol

clean:
	rm -rf ${CASTER_CONTROL}.app
	rm -rf ${RIBBON_GENERATOR}.app
	rm -rf Fins_build
	rm -rf ConfigFiles_build

castercontrol: ccstub ccapp

ribbongenerator: stub framework fins webapp
	

ccstub: 
	${PUBLIC_OBJECTIVEC}/mkapp ${CASTER_CONTROL}

ccapp: ccstub
		cp -rf CasterApp/* ${CASTER_CONTROL}.app/Contents/

stub: 
	${PUBLIC_OBJECTIVEC}/mkapp ${RIBBON_GENERATOR}

# note: Public.ObjectiveC must be available and built
#       Pike.framework must be present in the Public.ObjectiveC build directory
#       and must have Public.Parser.XML2 and Public.ObjectiveC modules installed.
#       additionally, Pike.framework must have been built with SQLite enabled.

framework: stub
	cp -rf RibbonGeneratorApp/* ${RIBBON_GENERATOR}.app/Contents/


fins: framework
	if [ ! -d Fins_build ]; then hg clone ${FINS_REPO}/Fins Fins_build; fi;
	if [ ! -d ConfigFiles_build ]; then hg clone ${FINS_REPO}/pike_modules/Public_Tools_ConfigFiles ConfigFiles_build; fi;
	cp -rf Fins_build/lib/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules
	mkdir -p ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod
	cp -rf ConfigFiles_build/module.pmod.in/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod/

webapp: fins
	cp -rf webapps/Keyboard ${RIBBON_GENERATOR}.app/Contents/Resources
	cp -rf modules/* ${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/modules
	cp -rf CHANGES ${RIBBON_GENERATOR}.app/Contents/Resources
