# Christian Koch <cfkoch@sdf.lonestar.org>

.PHONY: app test
.MAIN: app

APP_PROFILE=osxnbbuilder.platypus

PLATYPUS=/usr/local/bin/platypus
VERSION=0.1
APPNAME="NetBSD Builder"

app:
	$(PLATYPUS) -y -d \
		-p /usr/bin/env -G ruby \
		-o "Text Window" -b '#000000' -g '#ffffff' \
		-V $(VERSION) -a $(APPNAME) -i ./img/netbsd-tb.icns \
		-u "Christian Koch" -I net.christianfkoch.osxnbbuilder \
		-f ./osxnbbuilder/netbsdbuilder-pashua.conf \
		-f ./osxnbbuilder/app \
		-f ./osxnbbuilder/bin \
		-f ./osxnbbuilder/img \
		-f ./osxnbbuilder/lib \
		-f ./osxnbbuilder/libexec \
		-f ./osxnbbuilder/src \
		./osxnbbuilder/launch.rb \
		"./NetBSD Builder.app"

test:
	(cd osxnbbuilder && ./launch.rb -n)
