# Introduction

The **Document Availability Information API (DAIA)** defines model of document
availability, a set of exchangeable serializations of this model (in JSON, XML,
and RDF), and an HTTP API to query document availability information encoded in
any of these serializations. The DAIA data model basically consists of abstract
documents, concrete holdings of documents, and document services, each with an
availability status. 

## Status of this document

This document is a draft of what is going to be DAIA 1.0 specification.

The previous version 0.5 is available at <http://purl.org/NET/DAIA> and DAIA
ontology at <http://uri.gbv.de/ontology/daia/>.

The RDF ontology of DAIA/RDF is available in [Turtle](daia.ttl) and in
[RDF/XML](daia.owl). Schema files for DAIA/XML will follow. All documentation
and schemas are generated from the source file 
[`daia.md`](https://github.com/gbv/daiaspec/blob/master/daia.md) written in
[Pandoc’s Markdown](http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html)
and converted with [makespec](https://github.com/jakobib/makespec).

Updates and sources of DAIA 1.0 can be found at
<http://github.com/gbv/daiaspec>. The current version of this document was last
modified at GIT_REVISION_DATE with revision GIT_REVISION_HASH.

This document is publically available under the terms of the Creative-Commons
Attribution-No Derivative ([CC-ND 3.0]) license. Feedback is welcome:

* implement the specication!
* [correct](https://github.com/gbv/daiaspec/blob/master/daia.md) the specification!
* [comment](https://github.com/gbv/daiaspec/issues) on the specification!

**Revision history**

GIT_CHANGES

## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

## Namespaces

DAIA serializations in XML (DAIA/XML) and RDF (DAIA/RDF) are each formally
described by a schema or ontology. The DAIA/XML Schema is identified by the XML
namespace `http://ws.gbv.de/daia/`. The DAIA/RDF Ontology is identified by the
URI <http://purl.org/ontology/daia/> which is also used URI namespace. The
namespace prefix `daia` is recommeded for both DAIA/XML and DAIA/RDF.

    @prefix daia: <http://purl.org/ontology/daia/> .
    @base         <http://purl.org/ontology/daia/> .

The following namspace prefixes are used to refer to related ontologies:

    @prefix bibo: <http://purl.org/ontology/bibo/> .
    @prefix dct:  <http://purl.org/dc/terms/> .
    @prefix dso:  <http://purl.org/ontology/dso#> .
    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    @prefix org:  <http://www.w3.org/ns/org#> .
    @prefix owl:  <http://www.w3.org/2002/07/owl#> .
    @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
    @prefix vann: <http://purl.org/vocab/vann/> .
    @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

The current XML Schema is located at <http://purl.org/NET/DAIA/schema.xsd>. 


# Structure and Encoding

In the following paragraphs we want to give a short introduction to DAIA
format. Examples of equivalent DAIA document fragments are given in
DAIA/JSON and DAIA/XML. The basic information entities of DAIA format
are:

-   [daia](#root-element) (root element)
-   [document](#document-element)
-   [item](#item-element)
-   [available](#available-element) and [unavailable](#unavailable-element)
-   [messages](#messages)
-   [Additional entities](#additional-entities) (institution, department, storage, and limitation)

Daia entities in DAIA/JSON are encoded as simple nodes with child nodes,
daia entities in DAIA/XML are encoded as XML-elements with attributes
and child-elements. XML elements include namespaces so you must use an
XML parser with support of namespaces to process DAIA/XML. Below the
possible and mandatory attributes and child elements or nodes of each
daia entities are defined. If an entity is marked with a question mark
(`?`) it is optional. If an entity is marked with a star
(`\*`) it is repeatable and optional. All other entities are
mandatory and non-repeatable. Repeatable elements in DAIA/XML are just
line up after another. Repeatable elements in DAIA/JSON must be encoded
as array with one ore more content elements.


+--------------+------------------------------------+----------------------------+
|              | DAIA/JSON                          |  DAIA/XML                  |
+==============+====================================+============================+
| repeated     | ~~~ {.json}                        | ~~~ {.xml}                 |
|              | {                                  | <item ...> ... </item>     |
|              |  "item": [ { ... }, { ... }, ... ] | <item ...> ... </item>     |
|              | }                                  | ...                        |
|              | ~~~                                | ~~~                        |
+--------------+------------------------------------+----------------------------+
| not repeated | ~~~ {.json}                        | ~~~ {.xml}                 |
|              | {                                  | <item ...> ... </item>     |
|              |  "item": [ { ... } ]               | ~~~                        |
|              | }                                  |                            |
|              | ~~~                                |                            |
+--------------+------------------------------------+----------------------------+

Content of entities that must not have child nodes are encoded as Unicode
strings, numbers, or boolean values. Unless a more specific limitation is
defined with an XML Schema Datatype, the content must be an Unicode string (but
it may be the empty string). DAIA uses the following XML Schema Datatypes:

- `xs:boolean` - in DAIA/XML one of `true`, `false`,
  `1`, `0`. In DAIA/JSON one of `true`, `false` (but literally instead of string).
- `xs:language` - must conform to the pattern
  `[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})\*`.
- `xs:date` - must follow the form
  `\d{4}[-](\d\d)[-](\d\d)((([+-])\d\d:\d\d)|Z)?`.
- `xs:dateTime` - must follow the form
  `\d{4}[-](\d\d)[-](\d\d)[T](\d\d)[:](\d\d)[:]\d\d([.]\d+)?((([+-])\d\d:\d\d)|Z)?`.
- `xs:duration` - must follow the form `-PnYnMnDTnHnMnS`.
  Empty parts can be omitted.
- `xs:integer` - must conform to the pattern `[+-]?[0-9]+` in
  DAIA/XML. In DAIA/JSON it is an integer.
- `xs:nonNegativeInteger` - must conform to the pattern
  `([+]?[0-9]+|-0)` in DAIA/XML. In DAIA/JSON it is a non-negative integer.
- `xs:anyURI` - must conform to the pattern of an URI.

## Root element

Each full DAIA document contains exactly one
root element. In DAIA/XML the root element name is **`daia`**, in
DAIA/JSON the root element is just an unnamed object.

**Properties**

- **`version`** (attribute) - the daia version number (currently `0.5`)
- **`timestamp`** (attribute) - the time the document was generated. Type `xs:dateTime`.
- **`message`**\* (element) - (error) message(s) about the whole response
- **`institution`**? (element) - information about the
  institution that grants or knows about services and their
  availability
- **`document`**\* (element) - a group of items that can be
  refered to with one identifier. Please note that although the number
  of document elements can be zero or greater one, one single document
  entry should be considered as the default.

In DAIA/XML you must further specifiy the XML namespace
`http://ws.gbv.de/daia/` and may refer to the DAIA
XML Schema `http://ws.gbv.de/daia/daia.xsd` as
shown in the following example. In DAIA/JSON you can include a fixed
child element that points to the DAIA specification and namespace:

- **`schema`** (attribute) - DAIA namespace string
  `http://ws.gbv.de/daia/`

**Example** 

DAIA/JSON

~~~ {.json}
{
  "version" : "0.5",
  "schema" : "http://ws.gbv.de/daia/",
  "timestamp" : "2009-06-09T15:39:52.831+02:00",
  "institution" : { }
}
~~~

DAIA/XML

~~~ {.xml}
<daia xmlns="http://ws.gbv.de/daia/" version="0.5"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://ws.gbv.de/daia/ http://ws.gbv.de/daia/daia.xsd"
      timestamp="2009-06-09T15:39:52.831+02:00">
   <institution/>
</daia>
~~~

Equivalent DAIA/XML with different namespace prefix:

~~~ {.xml}
<d:daia xmlns:d="http://ws.gbv.de/daia/" version="0.5"
      xmlns:s="http://www.w3.org/2001/XMLSchema-instance"
      s:schemaLocation="http://ws.gbv.de/daia/ http://ws.gbv.de/daia/daia.xsd"
      timestamp="2009-06-09T15:39:52.831+02:00">
   <d:institution/>
</d:daia>
~~~

## Document element

The `document` element describes a single document. Nevertheless, several
*instances* of a document (e.g. copies of a book) can exist. For these
instances, have a look at the [item element](#item-element) below.

**Properties**

- **`id`** (attribute) - each document needs an unique id to
  query it (e.g. ISBN, ppn, etc.). Please consider that ids have to be
  URIs. Type `xs:anyURI`.
- **`href`**? (attribute) - a link to the document or to
  additional information. Type `xs:anyURI`.
- **`message`**\* (element) - (error) message(s) about the
  document.
- **`item`**\* (element) - an instance or copy of the queried
  document (correspondends to the FRBR class of same name).

In DAIA/XML messages and items can be mixed in any order.

**Example in DAIA/JSON**

~~~ {.json}
{
  "document" : [ {
    "href" : "https://kataloge.uni-hamburg.de/DB=1/PPNSET?PPN=57793371X",
    "id" : "gvk:ppn:57793371X",
    "item" : [ {  }, {  }, {  } ]
  } ]
}
~~~

**Example in DAIA/XML**

~~~ {.xml}
<document href="https://kataloge.uni-hamburg.de/DB=1/PPNSET?PPN=57793371X" 
          id="gvk:ppn:57793371X">
  <item/>
  <item/>
  <item/>
</document>
~~~

**Example in DAIA/RDF**

~~~ {.turtle}
<gvk:ppn:57793371X> a bibo:Document ;
  foaf:primaryTopicOf <https://kataloge.uni-hamburg.de/DB=1/PPNSET?PPN=57793371X> ;
  daia:exemplar [ ], [ ], [ ] .
~~~

## Item element

The `item` node references a single
instance (copy, URI, etc.) of a document. The availability information
is of course connected to the item nodes.

**Properties**

- **`id`**? (attribute) - again, each item (instance) may have
  an unique ID (e.g., an individual call number for a book). Please
  consider that ids have to be URIs. Type `xs:anyURI`.
- **`href`**? (attribute) - a link to the item or to additional
  information. Type `xs:anyURI`.
- **`part`**? (attribute) - indicate that the item only contains
  a part of the document (`part="narrower"`) or contains
  more than the document (`part="broader"`)
- **`message`**\* (element) - (error) message(s) about the item.
- **`label`**? (element) - a label that helps to identify and/or
  find the item (call number etc.)
- **`department`**? (element) - an administrative sub-entitity
  of the institution that is responsible for this item
- **`storage`**? (element) - a physical location of the item
  (stacks, floor etc.)
- **`available`**\* (element) - information about an available
  service with the item.
- **`unavailable`**\* (element) - information about an
  unavailable service with the item

Multiple service status can be given for an item represented by
different available/unavailable elements.

**Example in DAIA/JSON**

~~~ {.json}
{
    "item" : [ {
      "id" : "id:123",
      "message" : [ { "lang": "en", "content": "foo" } ],
      "department" : { "id": "id:abc" },
      "label" : "bar",
      "available" : [ {"service" : "presentation"}, 
                      {"service" : "loan"}, 
                      {"service" : "interloan"} ],
      "unavailable" : [ {"service" : "openaccess"} ]
    } ]
}
~~~

**Example in DAIA/XML**

~~~ {.xml}
<item id="id:123">
   <message lang="en">foo</message>
   <department id="id:abc" />
   <label>bar<label>
   <available service="presentation" />
   <available service="loan" />
   <available service="interloan" />
   <unavailable service="openaccess" />
</item>
~~~

**Example in DAIA/RDF**

~~~ {.turtle}
<id:123> a frbr:Item ;
  dct:description "foo"@en ; 
  daia:label "bar" ;
  daia:heldBy <id:abc> ;
  daia:availableFor [ a dso:Presentation ] ;
  daia:availableFor [ a dso:Loan ] ;
  daia:availableFor [ a dso:Interloan ] ;
  daia:unavailableFor [ a dso:Openaccess ] ;
<id:abc> a foaf:Organization ; dct:isPartOf [
  a foaf:Organization ; dct:hasPart <id:abc> ] .
~~~

In DAIA/RDF, an Item element corresponds to an instance of
[frbr:Item](http://purl.org/vocab/frbr/core#Item) . Partial items refer to
items which contain less (`narrower`) or more (`broader`) than the whole
document:

+----------------------+-------------------------------------------------------------------------+
| narrower in DAIA/XML | ~~~ {.xml}                                                              |
|                      | <document id="x:123">                                                   |
|                      |   <item id="x:ABC" part="narrower"/>                                    |
|                      | </document>                                                             |
|                      | ~~~                                                                     |
+----------------------+-------------------------------------------------------------------------+
| narrower in DAIA/RDF | ~~~ {.turtle}                                                           |
|                      | <x:123> a bibo:Document ; daia:narrowerExemplar <x:ABC> .               |  
|                      | <x:123> a bibo:Document ; dct:hasPart [ daia:exemplar <x:ABC> ] } .     |
|                      | ~~~                                                                     |
+----------------------+-------------------------------------------------------------------------+
| broader in DAIA/XML  | ~~~ {.xml}                                                              |
|                      | <document id="x:123">                                                   |
|                      |   <item id="x:ABC" part="broader"/>                                     |
|                      | </document>                                                             |
|                      | ~~~                                                                     |
+----------------------+-------------------------------------------------------------------------+
| broader in DAIA/RDF  | ~~~ {.turtle}                                                           |
|                      | <x:123> a bibo:Document ; daia:broaderExemplar <x:ABC> .                |
|                      | <x:123> a bibo:Document ; daia:exemplar [ dct:hasPart <x:ABC> ] } .     |
|                      | ~~~                                                                     |
+----------------------+-------------------------------------------------------------------------+

## Available element

The structure of an `available` element is:

- **`service`**? (attribute) - the specific service from the [Document Service Ontology] 
  (DSO). The value can be given as full URI or as simple name. A name
  is mapped to an URI by uppercasing the first letter and prepending the base
  URI <http://purl.org/ontology/dso#>. Multiple services
  are represented by multiple available/unavailable elements. Type
  enumeration or `xs:anyURI`.
- **`href`**? (attribute) - a link to perform, register or
  reserve the service. Type `xs:anyURI`.
- **`delay`**? (attribute) - a time period of estimated delay.
  Use `unknown` or an ISO time period. If missing, then there
  is probably no significant delay. Type `xs:duration` or the
  string `unknown`.
- **`message`**\* (element) - (error) message(s) about the
  specific availability status of the item.
- **`limitation`**\* (element) - more specific limitations of
  the availability status.

In DAIA/XML messages and limitations can be mixed in any order.

**Typical DSO Services used in DAIA**

`presentation` 
: <http://purl.org/ontology/dso#Presentation>\ 
  The item is accessible within the institution (in their rooms, in their intranet etc.).

`loan`
: <http://purl.org/ontology/dso#Loan>\
  The item is accessible outside of the institution (by lending or online access) for a limited time.

`openaccess`
: <http://purl.org/ontology/dso#Openaccess>\
  The item is accessible freely without any restrictions by the institution (Open Access or free copies).

`interloan`
: <http://purl.org/ontology/dso#Interloan>\
  The item is accessible mediated by another institution.

*unspecified*
: <http://purl.org/ontology/dso#DocumentService>\
  The item is accessible for an unspecified purpose by an unspecified way.

One MAY use custom service types, not specified in DSO, if these services are
specified with an URI as subclasses of
<http://purl.org/ontology/dso#DocumentService>.

If you omit the service element then the unspecified service must be assumed
(do not use the string `unspecified` or the empty string but just omit to
specify a service).

**Example in DAIA/JSON**

~~~ {.json}
{ 
  "available": [ { "service":"loan", "delay":"PT2H" 
}
~~~

**Example in DAIA/XML**

~~~ {.xml}
<available service="loan" delay="PT2H" />
~~~

**Example in DAIA/RDF**

~~~ {.turtle}
[ ] daia:availableFor [
  a dso:Loan ;
  daia:delay "PT2H"^^xsd:duration 
] .
~~~

## Unavailable element

The structure of an `unavailable` element is identical to the structure of the
available element in most cases.

- **`service}}?** (attribute) - see above
- **`href`**? (attribute) - see above
- **`expected`** (attribute) - A time period until the service
  will be available again. Use `unknown` or an ISO time period.
  If missing, then the service probably won't be available in the
  future. Type `xs:date` or `xs:dateTime` or the string
  `unknown`.
- **`message`**\* (element) - see above
- **`limitation`**\* (element) - more specific limitations of
  the availability status
- **`queue?`** (attribute) - the number of waiting requests for
  this service. Type `xs:nonNegativeInteger`.

If no `expected` element is given, it is not sure whether the item
will ever be available, so this is not the same as setting it to
`unknown`. If no `queue` element is given, it may (but does not
need to) be assumed as zero. In DAIA/XML messages and limitations can be
mixed in any order.

**Example in DAIA/JSON**

~~~ {.json}
{
    "unavailable": [ {
      "service":"presentation",
      "delay":"PT4H"
    } ]
}
~~~

**Example in DAIA/XML**

~~~ {.xml}
<unavailable service="presentation" delay="PT4H" />
~~~

**Example in DAIA/RDF**

~~~ {.turtle}
[ ] daia:unavailableFor [
  a dso:Presentation ;
  daia:delay "PT4H"^^xsd:duration 
] .
~~~

## Messages

Messages can occur at several places in a DAIA
response. The structure of a `message` element is:

- **`lang`** (attribute) - a [RFC 3066] language code. Type
  `xs:language`.
- **`content`** (string) - the message text, a simple string
  without further formatting.
- **`errno`**? (attribute) - an error code (integer value). Type
  `xs:integer`.

**Notes:**

- If `content` is an empty string, it should be removed in DAIA
  encodings. Applications may treat a missing `content` as the
  empty string.
- Messages are not meant to be shown to end-users, but only used for
  debugging. If you need a DAIA message to transport some relevant
  information, you likely try to use DAIA for the wrong purpose.

**Example:**

In DAIA/XML the `message` element is a repeatable XML element
with optional attributes `lang` and `errno` and the string
encoded as element content. In DAIA/JSON a `message` element is
an object with `lang`, `errno`, and `string` as
keys. Multiple messages are combined in a JSON array:


**Example in DAIA/JSON**

~~~ {.json}
{
  "message" : [ {
    "content":"request failed",
    "lang":"en"
  } ]
}
~~~

**Example in DAIA/XML**

~~~ {.xml}
<message lang="en">request failed</message>
~~~

**Example in DAIA/RDF**

~~~ {.turtle}
[ ] daia:message [ 
  rdfs:value "request failed"@en .
]
~~~


## Additional entities

In this section, the additional entries
institution, department, storage and limitation are discussed.

- **`institution`** nodes refer to an institution (e.g., the
  University of Hamburg), referenced by an ISIL, a hyperlink and/or a
  name. 

- **`department`** nodes refer to a single department of an
  institution, e.g., the Faculty of Computer Science of Bielefeld
  University. They should be used when the institution has an own library.

- **`storage`** nodes deliver information about the place where
  an item is stored ("2nd floor"). \* **`limitation`** nodes give
  information of limitations of the availability of an item

The data structure of all these nodes is identical and discussed below.

**Data structure**

- **`id`**? - a (persistent) identifier for the entity. Type
  `xs:anyURI`.
- **`href`**? - a URI linking to the entity. Type
  `xs:anyURI`.
- **`content`**? - a simple message text describing the entity.

If `content` is an empty string, it should be removed in DAIA
encodings. Applications may treat a missing `content` as the empty
string. It is recommended to supply an `id` property to point to a
taxonomy or authority record and a `href` property to provide a
hyperlink to information about the specified entity.

**Examples in DAIA/JSON and DAIA/XML**

~~~ {.json}
{
    "institution" : { "href" : "http://www.tib.uni-hannover.de" }
    ...
    "department" : { 
                     "id" : "info:isil/DE-7-022",
                     "content" : "Library of the Geographical Institute, Goettingen University"
                   }
    ...
    "limitation"  : { "content" : "3 day loan" }
}
~~~

~~~ {.xml}
<institution href="http://www.tib.uni-hannover.de"/>
...
<department id="info:isil/DE-7-022">Library of the Geographical Institute, Goettingen University</department> 
...
<limitation>3 day loan</limitation>
~~~

# 3. DAIA Ontology

All DAIA documents, given in DAIA/JSON or DAIA/XML can also be expressed in
RDF. The ontology used for this purpose is also called DAIA/RDF. DAIA Ontology
mainly consists of a set of classes and properties from related ontologies.

## Overview

DAIA ontology is based on the following RDF ontologies:

* The [Document Service Ontology](http://gbv.github.com/dso/) (DSO)
  defines document services which can be available or unavailable.
* FRBR and Bibliographic Ontology (bibo) is used to defined documents
* DAIA Items will be defined by a holding ontology to be created
* [Organization ontology](http://www.w3.org/TR/vocab-org/) may be used
  to refer to organizations and institutions.
* DAIA should be aligned with [Schema.org Ontology](http://schema.org/).
* ...

## Namespaces

The URI namespace of DAIA Ontology is <http://purl.org/ontology/daia#>. The
namespace prefix `daia` is recommended. The URI of DAIA Ontology as as a whole
is <http://purl.org/ontology/daia>.

    @prefix daia: <http://purl.org/ontology/daia#> .
    @base         <http://purl.org/ontology/daia> .

The following namspace prefixes are used to refer to related ontologies:

    @prefix dso:  <http://purl.org/ontology/dso#> .
    @prefix owl:  <http://www.w3.org/2002/07/owl#> .
    @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
    @prefix ssso: <http://purl.org/ontology/ssso#> .
    @prefix vann: <http://purl.org/vocab/vann/> .

In Turtle syntax, the ontology is defined as following:

    <> a owl:Ontology ;
        rdfs:label "Document Availability Information Ontology" ;
        rdfs:label "DAIA" ;
        vann:preferredNamespacePrefix "daia" .

## Documents and Holdings

...

## Services and Limitations

    ssso:ServiceEvent a owl:Class ;
        rdfs:isDefinedBy <http://purl.org/ontology/ssso> .

    dso:DocumentService a owl:Class ;
        rdfs:subClassOf ssso:ServiceEvent ;
        rdfs:isDefinedBy <http://purl.org/ontology/dso> .

    dso:Loan a owl:Class ;
        rdfs:subClassOf dso:DocumentService ;
        rdfs:isDefinedBy <http://purl.org/ontology/dso> .

    dso:Presentation a owl:Class ;
        rdfs:subClassOf dso:DocumentService ;
        rdfs:isDefinedBy <http://purl.org/ontology/dso> .

    dso:Interloan a owl:Class ;
        rdfs:subClassOf dso:DocumentService ;
        rdfs:isDefinedBy <http://purl.org/ontology/dso> .

    dso:OpenAccess a owl:Class ;
        rdfs:subClassOf dso:DocumentService ;
        rdfs:isDefinedBy <http://purl.org/ontology/dso> .

    ssso:Limitation a owl:Class ;
        rdfs:isDefinedBy <http://purl.org/ontology/ssso> .

    ssso:limits a owl:ObjectProperty ;
        rdfs:domain ssso:ServiceLimitation ;
        rdfs:range ssso:ServiceEvent ;
        rdfs:isDefinedBy <http://purl.org/ontology/ssso> .

    ssso:limitedBy a owl:ObjectProperty ;
        rdfs:domain ssso:ServiceEvent ;
        rdfs:range ssso:ServiceLimitation ;
        owl:inverseOf ssso:limits ;
        rdfs:isDefinedBy <http://purl.org/ontology/ssso> .

## Storage

A storage is a place where items are stored.

    daia:Storage a owl:Class .

## Availability

...

# 4. Query API

## DAIA Query API

A **DAIA-API** is provided in form of a **Base URL** that can be queried by
HTTP (or HTTPS) GET. The Base URL may contain fixed query parameters but it
must not contain the query parameters `id` and `format`. A DAIA query is
constructed of the Base URL and a query parameter **`id`** for the document URI
to be queried for and **`format`** with one of `xml` and `json`.  The value of
the `format` parameter is case insensitive. The response muste be a DAIA/XML
document for `format=xml` and a DAIA/JSON document for `format=json`. If no
`format` parameter is given or if the parameter value is no known value, a
DAIA/XML document may be returned, but you can also return other formats. In
particular a DAIA-API may return DAIA/RDF in RDF/XML for `format=rdfxml` and
DAIA/RDF in Turtle for `format=ttl`. The HTTP response code must be 200 for all
non-empty responses (DAIA/JSON and DAIA/XML) and 404 for empty responses (for
instance RDF/XML in Turtle format). Multiple document URIs can be provided by
concatenating them with the vertical bar (`|`, `%7C` in URL-Encoding) but a
DAIA server may limit queries to any positive number of URIs.

**Examples:**

 Base URL                       Document URIs                                  Format      Query URL 
------------------------------ ---------------------------------------------  ----------  ----------------------------------------------------------------------------
`http://example.com/`           `gvk:ppn:588923168`                            DAIA/XML    `http://example.com/?id=gvk:ppn:588923168&format=xml`
`http://example.com/?cmd=daia`  `gvk:ppn:588923168`                            DAIA/JSON   `http://example.com/?cmd=daia&id=gvk:ppn:588923168&format=json`
`http://example.com/`           `gvk:ppn:588923168` and `gvk:ppn:365058963`    DAIA/JSON   `http://example.com/?id=gvk:ppn:588923168%7Cgvk:ppn:365058963&format=json`

## DAIA Storage API (experimental)

The **DAIA-Storage-API** is an additional API, similar to the DAIA-API, but to
retrieve Storage information only.  The request parameter are also **`format`**
and **`id`** but the latter can be any Unicode character string (it is up to
the specific implementation of an DAIA-Storage-API what kinds of identifiers to
expect). Typical applications include mapping from call number to locations.
The request is limited to any combination of the elements `institution`,
`department`, `storage`, and `message`. A DAIA Storage API and a DAIA API *must
not* share the same base URL.

# References

- **[DATATYPES]** [XML Schema Part 2: Datatypes Second Edition](http://www.w3.org/TR/xmlschema-2/).
  W3C Recommendation 28 October 2004.
- **[DSO]** [Document Service Ontology] Work in Progress 2013
- **[HTTP]** [Hypertext Transfer Protocol - HTTP/1.1](http://tools.ietf.org/html/rfc2616).
  June 1999 (RFC 2616).
- **[JSON]** [JavaScript Object Notation](http://www.json.org/). (RFC 4627)
- **[SSSO]** [Simple Service Status Ontology] Work in Progress 2013
- **[URI]** [Uniform Resource Identifiers (URI): Generic Syntax](http://tools.ietf.org/html/rfc2396).
  August 1998 (RFC 2396).
- **[UNICODE]** [The Unicode Standard Version 5.0](http://www.unicode.org/versions/Unicode5.0.0/).
  The Unicode Consortium, 2007.
- **[XML]** [Extensible Markup Language (XML) 1.0 (Fifth Edition)](http://www.w3.org/TR/xml/).
  W3C Recommendation 26 November 2008
- **[XML-NS]** [Namespaces in XML 1.0 (Second Edition)](http://www.w3.org/TR/xml-names/).
  W3C Recommendation 16 August 2006

# Notes (Informative)

- A [reference implementation in Perl](http://search.cpan.org/perldoc?DAIA) 
  is available at CPAN. It includes a simple
  [DAIA validator and converter](http://search.cpan.org/perldoc?daia).
  A public installation of this validator is available at
  <http://daia.gbv.de/validator/>.
- All DAIA-related files are combined in a project at Sourceforge:
  <http://sourceforge.net/projects/daia/>.
- Date and Time values are from a subset of ISO 8601. Even in ISO 8601
  there are many ways to specify data and time - so if you need to
  interpret DAIA data and time values you should use a ISO 8601
  library to handle all its particularities and to normalize data and
  time values.
- The basic structure of DAIA is unlikely to change. However until
  DAIA 1.0 the following parts need to be finished: 

   -  Definition of canonical DAIA
   -  Inclusion of some additional obvious constraints like uniqueness of identifiers per document.
   -  The DAIA/XML namespace (currently <http://ws.gbv.de/daia/>) may be changed to a more stable PURL.

## Relevant differences to DAIA 0.5

The main difference of this specification to DAIA 0.5 is the inclusion of
DAIA/RDF which was formerly defined in a separate document. Major parts of the
DAIA ontology have been moved to independent micro-ontologies, involving the
change of URIs. In particular, DAIA services are now defined in the Document
Service Ontology. The following URIs are deprecated:

Removed:

* <http://purl.org/ontology/daia/Response>
* <http://purl.org/ontology/daia/timestamp>

Moved to [Document Service Ontology] (DSO):

* <http://purl.org/ontology/daia/Service>
  moved to <http://purl.org/ontology/dso#DocumentService>
* <http://purl.org/ontology/daia/Service/Openaccess>
  moved to <http://purl.org/ontology/dso#Openaccess>
* <http://purl.org/ontology/daia/Service/Interloan>
  moved to <http://purl.org/ontology/dso#Interloan>
* <http://purl.org/ontology/daia/Service/Loan>
  moved to <http://purl.org/ontology/dso#Loan>
* <http://purl.org/ontology/daia/Service/Presentation> 
  moved to <http://purl.org/ontology/dso#Presentation>

Moved to [Simple Service Status Ontology] (SSSO):

* <http://purl.org/ontology/daia/provides>
  moved to <http://purl.org/ontology/ssso#provides>
* <http://purl.org/ontology/daia/providedBy>
  moved to <http://purl.org/ontology/ssso#providedBy>
* <http://purl.org/ontology/daia/Limitation>
  moved to <http://purl.org/ontology/ssso#ServiceLimitation>
* <http://purl.org/ontology/daia/limits>
  moved to <http://purl.org/ontology/ssso#limits>
* <http://purl.org/ontology/daia/limitedBy>
  moved to <http://purl.org/ontology/ssso#limitedBy>
* <http://purl.org/ontology/daia/queue>
  moved to <http://purl.org/ontology/ssso#queue>
* <http://purl.org/ontology/daia/delay> 
  and <http://purl.org/ontology/daia/expected> 
  moved to <http://purl.org/ontology/ssso#delay>

Moved to [Holding Ontology]:

* <http://purl.org/ontology/daia/exemplar> 
  moved to ...
* <http://purl.org/ontology/daia/exemplarOf> 
  moved to ...
* <http://purl.org/ontology/daia/narrowerExemplar> 
  moved to ...
* <http://purl.org/ontology/daia/narrowerExemplarOf> 
  moved to ...
* <http://purl.org/ontology/daia/broaderExemplar> 
  moved to ...
* <http://purl.org/ontology/daia/broaderExemplarOf> 
  moved to ...
* <http://purl.org/ontology/daia/holds> 
  moved to ...
* <http://purl.org/ontology/daia/heldBy> 
  moved to ...

Nur sure about:

* daia:label
* daia:collectedBy, daia:inCollection (?) to connect holding institution/agent 
  and abstract document which holding is exemplar of.
* daia:Storage maybe to be replaced by dct:Location, geo:SpatialThing or similar (?)

The remaining DAIA/RDF classes and properties may be the **core of DAIA
ontology** (or moved to another ontology, such as DSO?):

* daia:perform, daia:baseURL ...

* <http://purl.org/ontology/daia/availableOf> changed to
  <http://purl.org/ontology/daia#availableOf>.

* <http://purl.org/ontology/daia/availableFor> changed to
  <http://purl.org/ontology/daia#availableFor>.

* <http://purl.org/ontology/daia/unavailableOf> changed to
  <http://purl.org/ontology/daia#unavailableOf>.

* <http://purl.org/ontology/daia/unavailableFor> changed to
  <http://purl.org/ontology/daia#unavailableFor>.

## Integrity rules

If department and institution have same id, the department SHOULD be
ignored.

[CC-ND 3.0]: http://creativecommons.org/licenses/by-nd/3.0/
[RFC 3066]: http://tools.ietf.org/html/rfc3066

[Document Service Ontology]: http://gbv.github.com/dso/dso.html
[Simple Service Status Ontology]: http://purl.org/ontology/ssso
[Holding Ontology]: https://github.com/cKlee/holding-ontology

