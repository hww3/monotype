PUBLIC_OBJECTIVEC=/Users/hww3/Public_ObjectiveC
FINS_REPO="http://hg.welliver.org/"
RIBBON_GENERATOR=RibbonGenerator
#all: stub framework fins webapp

ribbongenerator: stub framework fins webapp
	

stub: 
	${PUBLIC_OBJECTIVEC}/mkapp ${RIBBON_GENERATOR}

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