#
# Makefile for phpDAIA
#

SOURCES = daia.php
DISTFILE = phpdaia.tgz

APIDOC = doc
comma = ,
empty =
space = $(empty) $(empty)
SOURCELIST = $(subst $(space),$(comma),${SOURCES})

doc:	${SOURCES}
	rm -rf ${APIDOC} && mkdir ${APIDOC} && \
	phpdoc -f ${SOURCELIST} -o HTML:Smarty:PHP -d tutorials -t ${APIDOC} -dn phpDAIA -ti "phpDAIA"

clean:
	@rm -rf ${APIDOC} ${DISTFILE}

test:
	@php test.php

dist:   ${SOURCES}
	@tar -czfh ${DISTFILE} -T MANIFEST

.PHONY: clean test
