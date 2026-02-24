#!/bin/bash

PrepareFilesForCacheDE() {
	mkdir -p $SKYCAIRBUILDERPATH/caches > /dev/null 2>&1
	cp -r $SKYCAIRBUILDERPATH/caches/ $SKYCAIRBUILDERPATH/caches-bkp
	PrepareFilesForCache
}

PrepareFilesForCache() {
	# ldconfig to fix/update broken symlinks
	ldconfig -r $MODULEPATH/packages/

	# copy mime packages to build /usr/share/mime/mime.cache
	mkdir -p $SKYCAIRBUILDERPATH/caches/mime/packages > /dev/null 2>&1
	cp $MODULEPATH/packages/usr/share/mime/packages/* $SKYCAIRBUILDERPATH/caches/mime/packages > /dev/null 2>&1

	# copy desktop files to build /usr/share/applications/mimeinfo.cache
	mkdir $SKYCAIRBUILDERPATH/caches/applications > /dev/null 2>&1
	cp $MODULEPATH/packages/usr/share/applications/*.desktop $SKYCAIRBUILDERPATH/caches/applications/ > /dev/null 2>&1

	# copy glib schemas to build /usr/share/glib-2.0/schemas/gschemas.compiled
	mkdir $SKYCAIRBUILDERPATH/caches/schemas > /dev/null 2>&1
	cp $MODULEPATH/packages/usr/share/glib-2.0/schemas/*.xml $SKYCAIRBUILDERPATH/caches/schemas/ > /dev/null 2>&1

	# copy gdkpixbuf files to build /usr/lib64/gdk-pixbuf-2.0/2.10.0/loaders.cache
	mkdir -p $SKYCAIRBUILDERPATH/caches/gdk-pixbuf-2.0/2.10.0/loaders > /dev/null 2>&1
	cp $MODULEPATH/packages/usr/lib$SYSTEMBITS/gdk-pixbuf-2.0/2.10.0/loaders/*.so $SKYCAIRBUILDERPATH/caches/gdk-pixbuf-2.0/2.10.0/loaders > /dev/null 2>&1
}

GenerateCachesDE() {
	GenerateCaches
	rm -r $SKYCAIRBUILDERPATH/caches
	mv $SKYCAIRBUILDERPATH/caches-bkp $SKYCAIRBUILDERPATH/caches
}

GenerateCaches() {
	mkdir -p $MODULEPATH/packages/usr/share/mime > /dev/null 2>&1
	update-mime-database $SKYCAIRBUILDERPATH/caches/mime
	cp $SKYCAIRBUILDERPATH/caches/mime/mime.cache $MODULEPATH/packages/usr/share/mime/

	mkdir -p $MODULEPATH/packages/usr/share/applications > /dev/null 2>&1
	update-desktop-database $SKYCAIRBUILDERPATH/caches/applications
	cp -r $SKYCAIRBUILDERPATH/caches/applications/mimeinfo.cache $MODULEPATH/packages/usr/share/applications/

	mkdir -p $MODULEPATH/packages/usr/share/glib-2.0/schemas > /dev/null 2>&1
	glib-compile-schemas $SKYCAIRBUILDERPATH/caches/schemas
	cp -r $SKYCAIRBUILDERPATH/caches/schemas/gschemas.compiled $MODULEPATH/packages/usr/share/glib-2.0/schemas/

	mkdir -p $MODULEPATH/packages/usr/lib$SYSTEMBITS/gdk-pixbuf-2.0/2.10.0 > /dev/null 2>&1
	gdk-pixbuf-query-loaders $SKYCAIRBUILDERPATH/caches/gdk-pixbuf-2.0/2.10.0/loaders/*.so > $MODULEPATH/packages/usr/lib$SYSTEMBITS/gdk-pixbuf-2.0/2.10.0/loaders.cache
	sed -i "s|$SKYCAIRBUILDERPATH/caches|/usr/lib$SYSTEMBITS|g" $MODULEPATH/packages/usr/lib$SYSTEMBITS/gdk-pixbuf-2.0/2.10.0/loaders.cache
}
