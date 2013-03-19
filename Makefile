SPARKLE_HOME=${HOME}/Downloads/Sparkle 1/
PUBLIC_OBJECTIVEC=${HOME}/devel/Public_ObjectiveC
FINS_REPO="https://hg.welliver.org"
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
	@ls -l ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip
	@/bin/echo -n "Ribbon Generator Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem
	@ls -l ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip

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
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/Resources"
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/PkgInfo"
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/Info.plist"

rgapply_versions:
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/Resources"
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/PkgInfo"
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/Info.plist"

ccstub: 
	if [ ! -d Caster.app ]; then "${PUBLIC_OBJECTIVEC}/mkapp" "${CASTER_CONTROL}"; fi
	cp -Rf "external_modules" "${CASTER_CONTROL}.app/Contents/Resources/modules"
	cp -Rf "${SPARKLE_HOME}/Sparkle.framework" "${CASTER_CONTROL}.app/Contents/Frameworks"

ccapp: 
		cp -Rf CasterApp/* ${CASTER_CONTROL}.app/Contents/
		cp -Rf Common/* ${CASTER_CONTROL}.app/Contents/Resources/

stub: 
	if [ ! -d RibbonGenerator.app ]; then "${PUBLIC_OBJECTIVEC}/mkapp" "${RIBBON_GENERATOR}"; fi
	cp -Rf "external_modules" "${RIBBON_GENERATOR}.app/Contents/Resources/modules"
	cp -Rf "${SPARKLE_HOME}/Sparkle.framework" "${RIBBON_GENERATOR}.app/Contents/Frameworks"

framework: 
	cp -Rf RibbonGeneratorApp/* "${RIBBON_GENERATOR}.app/Contents/"


fins: framework
	if [ ! -d Fins_build ]; then hg clone ${FINS_REPO}/fins Fins_build; fi;
	if [ ! -d ConfigFiles_build ]; then hg clone ${FINS_REPO}/pike_modules-public_tools_configfiles ConfigFiles_build; fi;
	cp -Rf Fins_build/lib/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules
	mkdir -p ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod
	cp -Rf ConfigFiles_build/module.pmod.in/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod/

webapp: fins
	cp -Rf webapps/Keyboard "${RIBBON_GENERATOR}.app/Contents/Resources"
	cp -Rf modules/* "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/modules"
	cp -Rf CHANGES "${RIBBON_GENERATOR}.app/Contents/Resources"
