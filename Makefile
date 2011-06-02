SPARKLE_HOME=/Users/hww3/Downloads/Sparkle 1/
PUBLIC_OBJECTIVEC=/Users/hww3/devel/Public_ObjectiveC
FINS_REPO="http://hg.welliver.org/"
RIBBON_GENERATOR=RibbonGenerator
CASTER_CONTROL=Caster
PRIVATE_KEY_DIR=/Users/hww3/Dropbox/Development/Sparkle

# note: Public.ObjectiveC must be available and built
#
#       Pike.framework must be present in the Public.ObjectiveC build directory
#       and must have Public.Parser.XML2, Public.IO.IOWarror and Public.ObjectiveC 
#		modules installed.
#
#       additionally, Pike.framework must have been built with SQLite enabled.

all: RibbonGenerator.app Caster.app

hash: zip
	@/bin/echo
	@/bin/echo -n "Caster Control Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem
	@/bin/echo -n "Ribbon Generator Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem

zip: all
	zip -ry ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip ${CASTER_CONTROL}.app
	zip -ry ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip ${RIBBON_GENERATOR}.app

clean:
	rm -rf ${CASTER_CONTROL}.app
	rm -rf ${RIBBON_GENERATOR}.app
	rm -rf Fins_build
	rm -rf ConfigFiles_build

Caster.app: ccstub ccapp ccapply_versions

RibbonGenerator.app: stub framework fins webapp rgapply_versions

ccapply_versions:
	pike tools/apply_versions.pike version.cfg ${CASTER_CONTROL}.app 

rgapply_versions:
	pike tools/apply_versions.pike version.cfg ${RIBBON_GENERATOR}.app

ccstub: 
	${PUBLIC_OBJECTIVEC}/mkapp ${CASTER_CONTROL}
	cp -rf "${SPARKLE_HOME}/Sparkle.framework" ${CASTER_CONTROL}.app/Contents/Frameworks

ccapp: ccstub
		cp -rf CasterApp/* ${CASTER_CONTROL}.app/Contents/

stub: 
	${PUBLIC_OBJECTIVEC}/mkapp ${RIBBON_GENERATOR}
	cp -rf "${SPARKLE_HOME}/Sparkle.framework" ${RIBBON_GENERATOR}.app/Contents/Frameworks

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
