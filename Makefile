SPARKLE_HOME=${HOME}/SparkleShare/hww3/Development/SparkleDist
PUBLIC_OBJECTIVEC=${HOME}/devel/Public_ObjectiveC
FINS_REPO="https://hg.welliver.org"
RIBBON_GENERATOR=RibbonGenerator
CASTER_CONTROL=Caster
PUNCH=Punch
PRIVATE_KEY_DIR=${HOME}/SparkleShare/hww3/Development/Sparkle
DEPLOY_DEST=/srv/delta-home/keyboard-deploy

# note: Public.ObjectiveC must be available and built
#
#       Pike.framework must be present in the Public.ObjectiveC build directory
#       and must have Public.Parser.XML2, Public.IO.IOWarror and Public.ObjectiveC 
#		modules installed.
#
#       additionally, Pike.framework must have been built with SQLite enabled.

all: RibbonGenerator.app Caster.app Punch.app

hash: zip
	@/bin/echo
	@/bin/echo -n "Caster Control Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem
	@ls -l ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip
	@/bin/echo -n "Ribbon Generator Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem
	@ls -l ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip
	@/bin/echo -n "Punch Hash: "
	@ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${PUNCH}-`pike tools/get_value.pike version.cfg punchVersion`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem
	@ls -l ${PUNCH}-`pike tools/get_value.pike version.cfg punchVersion`.zip

	@HASH=`ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${RIBBON_GENERATOR}-\`pike tools/get_value.pike version.cfg ribbonGeneratorVersion\`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem` \
        DATE=`date` \
	VERSION=`pike tools/get_value.pike version.cfg ribbonGeneratorVersion` \
	SIZE=`ls -l ${RIBBON_GENERATOR}-\`pike tools/get_value.pike version.cfg ribbonGeneratorVersion\`.zip | cut -d ' ' -f8` \
	APP="RibbonGenerator" \
	pike tools/appcast.pike appcast.xml;
	@HASH=`ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${CASTER_CONTROL}-\`pike tools/get_value.pike version.cfg casterControlVersion\`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem` \
        DATE=`date` \
	VERSION=`pike tools/get_value.pike version.cfg casterControlVersion` \
	SIZE=`ls -l ${CASTER_CONTROL}-\`pike tools/get_value.pike version.cfg casterControlVersion\`.zip | cut -d ' ' -f8` \
	APP="Caster" \
	pike tools/appcast.pike appcast.xml;
	@HASH=`ruby "${SPARKLE_HOME}/Extras/Signing Tools/sign_update.rb" ${PUNCH}-\`pike tools/get_value.pike version.cfg punchVersion\`.zip ${PRIVATE_KEY_DIR}/dsa_priv.pem` \
        DATE=`date` \
	VERSION=`pike tools/get_value.pike version.cfg punchVersion` \
	SIZE=`ls -l ${PUNCH}-\`pike tools/get_value.pike version.cfg punchVersion\`.zip | cut -d ' ' -f8` \
	APP="Punch" \
	pike tools/appcast.pike appcast.xml; \
	
zip: all
	zip -ry ${CASTER_CONTROL}-`pike tools/get_value.pike version.cfg casterControlVersion`.zip ${CASTER_CONTROL}.app
	zip -ry ${RIBBON_GENERATOR}-`pike tools/get_value.pike version.cfg ribbonGeneratorVersion`.zip ${RIBBON_GENERATOR}.app
	zip -ry ${PUNCH}-`pike tools/get_value.pike version.cfg punchVersion`.zip ${PUNCH}.app

clean:
	rm -rf ${CASTER_CONTROL}.app
	rm -rf ${PUNCH}.app
	rm -rf ${RIBBON_GENERATOR}.app
	rm -rf Fins_build
	rm -rf ConfigFiles_build

Caster.app: ccstub ccapp ccapply_versions

Punch.app: punchstub punchresources punchapply_versions

RibbonGenerator.app: stub framework fins webapp cleanup_app rgapply_versions

cleanup_app:
	-rm "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/config/Keyboard.sqlite3"
	-rm "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/logs/debug.log"
	-rm "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/logs/access.log"

ccapply_versions:
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/Resources"
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/PkgInfo"
	pike tools/apply_versions.pike version.cfg "${CASTER_CONTROL}.app/Contents/Info.plist"

punchapply_versions:
	pike tools/apply_versions.pike version.cfg "${PUNCH}.app/Contents/Resources"
	pike tools/apply_versions.pike version.cfg "${PUNCH}.app/Contents/PkgInfo"
	pike tools/apply_versions.pike version.cfg "${PUNCH}.app/Contents/Info.plist"

rgapply_versions:
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/Resources"
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/PkgInfo"
	pike tools/apply_versions.pike version.cfg "${RIBBON_GENERATOR}.app/Contents/Info.plist"

ccstub: 
	if [ ! -d Caster.app ]; then pike "${PUBLIC_OBJECTIVEC}/mkapp.pike" "${CASTER_CONTROL}"; fi
	cp -Rf "external_modules" "${CASTER_CONTROL}.app/Contents/Resources/modules"
	cp -Rf "${SPARKLE_HOME}/Sparkle.framework" "${CASTER_CONTROL}.app/Contents/Frameworks"

stub: 
	if [ ! -d RibbonGenerator.app ]; then pike "${PUBLIC_OBJECTIVEC}/mkapp.pike" "${RIBBON_GENERATOR}"; fi
	cp -Rf "external_modules" "${RIBBON_GENERATOR}.app/Contents/Resources/modules"
	cp -Rf "${SPARKLE_HOME}/Sparkle.framework" "${RIBBON_GENERATOR}.app/Contents/Frameworks"

ccapp: 
	cp -Rf CasterApp/* ${CASTER_CONTROL}.app/Contents/
	cp -Rf Common/* ${CASTER_CONTROL}.app/Contents/Resources/

punchresources: 
	cp -Rf PunchApp/* ${PUNCH}.app/Contents/
	cp -Rf Common/* ${PUNCH}.app/Contents/Resources/

punchstub: 
	if [ ! -d Punch.app ]; then pike "${PUBLIC_OBJECTIVEC}/mkapp.pike" "${PUNCH}"; fi
	cp -Rf "external_modules" "${PUNCH}.app/Contents/Resources/modules"
	cp -Rf "${SPARKLE_HOME}/Sparkle.framework" "${PUNCH}.app/Contents/Frameworks"

framework: 
	cp -Rf RibbonGeneratorApp/* "${RIBBON_GENERATOR}.app/Contents/"

prereqs: dojo
	if [ ! -d Fins_build ]; then hg clone ${FINS_REPO}/fins Fins_build; fi;
	if [ ! -d ConfigFiles_build ]; then hg clone ${FINS_REPO}/pike_modules-public_tools_configfiles ConfigFiles_build; fi;

fins: framework prereqs
	cp -Rf Fins_build/lib/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules
	mkdir -p ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod
	cp -Rf ConfigFiles_build/module.pmod.in/* ${RIBBON_GENERATOR}.app/Contents/Frameworks/Pike.framework/Resources/lib/modules/Public.pmod/Tools.pmod/ConfigFiles.pmod/

deploy: prereqs
	mkdir -p "${DEPLOY_DEST}"
	cp -Rf webapps/Keyboard "${DEPLOY_DEST}"
	cp -Rf Fins_build/lib "${DEPLOY_DEST}/Keyboard"
	cp -Rf modules/* "${DEPLOY_DEST}/Keyboard/modules"
	cp -rf CHANGES "${DEPLOY_DEST}/"
	cp -Rf dojo-release-1.6.1-src/release/dojo "${DEPLOY_DEST}/Keyboard"
	pike tools/apply_versions.pike version.cfg "${DEPLOY_DEST}/Keyboard"

webapp: fins phantomjs
	cp -Rf webapps/Keyboard "${RIBBON_GENERATOR}.app/Contents/Resources"
	cp -Rf modules/* "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/modules"
	cp -Rf CHANGES "${RIBBON_GENERATOR}.app/Contents/Resources"
	cp -Rf dojo-release-1.6.1-src/release/dojo "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard"
	cp -Rf phantomjs-1.9.7-macosx/bin/phantomjs "${RIBBON_GENERATOR}.app/Contents/Resources/Keyboard/bin"

testsuite: testsuite.in
	/usr/local/pike/8.0.1/include/pike/mktestsuite testsuite.in > testsuite

verify:	testsuite
	pike -Mmodules -x test_pike testsuite

phantomjs:
	if [ ! -f phantomjs-1.9.7-macosx.zip ]; then wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-macosx.zip; \
	unzip phantomjs-1.9.7-macosx.zip; fi; 
dojo:
	if [ ! -f dojo-release-1.6.1-src.tar.gz ]; then wget http://download.dojotoolkit.org/release-1.6.1/dojo-release-1.6.1-src.tar.gz; fi;
	tar xzf dojo-release-1.6.1-src.tar.gz
	cp tools/monotype.profile.js dojo-release-1.6.1-src/util/buildscripts/profiles
	cp webapps/Keyboard/static/MatrixEditor.js dojo-release-1.6.1-src/dijit/form
	cd dojo-release-1.6.1-src/util/buildscripts && ./build.sh action=release profile=monotype version=1.6.1-release
	
