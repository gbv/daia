#
# Makefile for DAIA XSLT client
#

DISTFILE = daiaxslt.tgz

clean:
	@rm -rf ${DISTFILE}

test:
	@xsltproc daia.xsl *.xml > /dev/null 

tardist: dist

dist:   
	@tar -czf ${DISTFILE} -T MANIFEST

.PHONY: clean test dist tardist
