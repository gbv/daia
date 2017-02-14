# Introduction

The **Document Availability Information API (DAIA)** is a HTTP based
programming interface to query information about current availability of
documents in libraries.

## Status of this document

This document is managed in a public git repository hosted at
<http://github.com/gbv/daia>. The specification can be distributed freely under
the terms of [CC-BY-SA](http://creativecommons.org/licenses/by-sa/3.0/).

See the [list of releases](#releases) for updates.

## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119].

# Data format

The DAIA data model basically consists of abstract [documents], concrete
holdings of documents ([items]), and document [services], with an availability
status. The data model is encoded in JSON as [DAIA Response].  Additional
[integrity rules] ensure that a DAIA Response and parts of it can also be
mapped to other data formats such as RDF.

A non-normative [JSON Schema] is included in the appendix.

## Simple data types

[entity]: #simple-data-types

The following data types are used to defined [DAIA Response] format.

string
  : A Unicode string. A DAIA client MUST treat fields with empty string value
    equal to non-existing fields. Strings SHOULD be normalized to Unicode
    Normalization Form C (NFC).

URI
  : A syntactically correct URI.

URL
  : A syntactically correct URL with HTTPS (RECOMMENDED) or HTTP scheme.

count
  : A non-negative integer.

boolean
  : A Boolean value (`true` or `false`).

datetime
  : An instant of time specified in the form `YYYY-MM-DDThh:mm:ss(.ss)?(Z|[+-]hh:mm)?`
    as defined with [XML Schema datatype xsd:dateTime](http://www.w3.org/TR/xmlschema-2/#dateTime).
    A timezone indicator SHOULD be included.

anydate
  : A date as defined with [XML Schema datatype xsd:date](http://www.w3.org/TR/xmlschema-2/#date)
    (`YYYY-MM-DD(Z|[+-]hh:mm)?`), a datetime as defined above, or the string `unknown`.
    A timezone indicator SHOULD be included.

duration
  : A duration as defined with
    [XML Schema datatype xsd:duration](http://www.w3.org/TR/xmlschema-2/#duration)
    or the string `unknown`.

service
  : An URI or a string with one of values `presentation`, `loan`, `remote`, 
    `interloan`, and `openaccess`. DAIA clients SHOULD ignore other non-URI values.

entity
  : A non-empty JSON object with the following fields:

    name    type                description
    ------- ------- ----------- --------------------------------------------------------
    id      URI     RECOMMENDED globally unique identifier of the entity
    href    URL     OPTIONAL    web page about the entity
    content string  OPTIONAL    human-readable label, title or description of the entity
    ------- ------- ----------- --------------------------------------------------------

    The language of field `content` SHOULD be given with HTTP [response header]
    `Content-Language`. A DAIA client MAY use the `id` field to retrieve
    additional information about the entity and it MAY override fields `href`
    and/or `content` with this information.

<div class="example">
The following entity describes the Library of Congress:

`examples/entity.json`{.include .codeblock .json}

Additional information about this entity can be retrieved as Linked Open Data
via <http://viaf.org/viaf/151962300>.
</div>

## DAIA Response

[DAIA Response]: #daia-response

A **DAIA Response** is a JSON object with one REQUIRED and four OPTIONAL fields:

name        type                          description
----------- -------------------- -------- ----------------------------------------------------------------------
document    array of [documents] REQUIRED documents matching the processed [request identifiers]
institution [entity]             OPTIONAL institution that grants or knows about services and their availability
timestamp   datetime             OPTIONAL time the DAIA Response was generated
$schema     URL                  OPTIONAL link to a JSON Schema document
@context    URL                  OPTIONAL link to a JSON-LD context document
----------- -------------------- -------- ----------------------------------------------------------------------

A DAIA Response sent by a DAIA server in response to a request MUST only
contain [documents] matching queried [request identifiers]. A document matches
a given request identifier if the request identifier is repeated in document
field `id`, `requested`, or both. A DAIA Response MAY contain multiple
documents that match the same request identifier.

DAIA clients MUST treat fields with empty JSON arrays (possible fields
`document`, `item`, `available`, `unavailable`, and `limitation`) equal to
non-existing fields.  A DAIA server MAY include additional fields not included
in this specification. Additional fields SHOULD be ignored by DAIA clients.

<div class="note">
DAIA Response format is not a flat data structure (see [DAIA Simple] for a very
condensed alternative). To uniquely refer to fields within this nested structure
it makes sense to use a JSON path or JSPath expression, such as `institution.href`,
`document.*.item`, or `document[0].item.*.available{.service == "loan"}`.
</div>

<div class="note">
DAIA was primarily designed to query availability of documents with known URIs,
so the mapping from [request identifier] to document or item identifier is
straightforward in most cases. DAIA server may support more complicated
mappings to normalize identifiers or to look up documents with unknown URI.
For instance, a document with known ISSN, volume, and page could be queried
with an OpenURL <http://example.org/?issn=0302-9743&volume=9341&spage=26> and
the following DAIA Response:

```json
{
  "document": [ {
    "requested": "http://example.org/?issn=0302-9743&volume=9341&spage=26",
    "id": "http://dx.doi.org/10.1007/978-3-319-25639-9_5",
    "item": [ {
      "available": [ {
        "service": "openaccess",
        "href": "http://csarven.ca/this-paper-is-a-demo"
      } ]
    } ]
  } ]
}
```
</div>

## Documents

[documents]: #documents

A **document** is a JSON object with one REQUIRED and four OPTIONAL fields:

name      type                      description
--------- ---------------- -------- -------------------------------------------
id        URI              REQUIRED globally unique identifier of the document
requested string           OPTIONAL [request identifier] matching this document
href      URL              OPTIONAL web page about the document
about     string           OPTIONAL human-readable description of the document
item      array of [items] OPTIONAL set of instances or copies of the document
--------- ---------------- -------- -------------------------------------------

Documents typically refer to works or editions of publications.

<div class="example">
A DAIA server at `http://example.org/` is queried with [request identifier]
`PPN 62486362X`.

The DAIA server returns an institution and a document. The
request identifier is mapped to the document URI `http://d-nb.info/1001703464`:

```
GET /?format=json&id=PPN%2062486362X HTTP/1.1
Host: example.org
User-Agent: MyDAIAClient/1.0
Accept: application/json

HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Language: en
X-DAIA-Version: 1.0.0
```

`examples/response-1.json`{.include .codeblock .json}
</div>

## Items

[items]: #items
[item]: #items

An **item** is a JSON object with the following fields:

name        type                               description
----------- ---------------------- ----------- ---------------------------------------------------------------
id          URI                    RECOMMENDED globally unique identifier of the item
href        URL                    OPTIONAL    web page about the item
part        string                 OPTIONAL    whether and how the item is partial
label       string                 OPTIONAL    call number or similar item label for finding or identification
about       string                 OPTIONAL    human-readable description of the item
chronology  [chronology]           OPTIONAL    chronology or enumeration of the item
department  [entity]               OPTIONAL    an administrative sub-entitity of the institution
storage     [entity]               OPTIONAL    a physical location of the item (stacks, floor etc.)
available   array of [available]   OPTIONAL    set of available [services]
unavailable array of [unavailable] OPTIONAL    set of unavailable [services]
----------- ---------------------- ----------- ------------------------------------------------------

Items refer to particular copies or holdings of documents. The value of field
`part` MUST be one of `narrower` and `broader`, if given.  Partial items refer
to items which contain less (`narrower`) or more (`broader`) than the whole
document. Some items MAY be identical with their document, for instance
indistinguishable digital copies of a digital document. The field `part` MUST NOT
be set in this case.

The `department` refers to a department of an institution that is resposible
for or knows about availability of the item. DAIA clients SHOULD assume a
general hierarchy between `institution`, `department`, and `storage`.

<div class="example">
The following DAIA Response contains two documents in response to the request
identifier `10.1007/978-3-531-19144-7_13`. The first document is a printed
collection that contains the requested article as one part (`part` is
`broader`). A copy of the collection is available for loan. The second document
is a digital edition of the article. A copy of this article can be used within
the the institution and for short time loan but it is not available as Open
Access.

`examples/response-2.json`{.include .codeblock .json}
</div>

## Services

[service]: #services
[services]: #services
[service types]: #services

A service is something that an item is currently accessible or unaccessible for
([availability] fields `available` and `unavailable` of [item]). Each service
has a **service type** to define what can be done with a given item. A service
type MUST be identified by an URI. Abbreviated names SHOULD be used for the
following predefined DAIA service types.

A DAIA server SHOULD NOT omit services because of assumed implications between
service types (for instance most times an item is available for loan it is also
available for presentation) but include all service types it knows about.

### presentation {.unnumbered}

The service type <http://purl.org/ontology/dso#Presentation>, abbreviated as
`presentation`, indicates that an item is made accessible within the
institution or department.


### loan {.unnumbered}

The service type <http://purl.org/ontology/dso#Loan>, abbreviated as `loan`,
indicates that an item is made accessible outside of the institution or
department for a limited time and having been picked up there.

### remote {.unnumbered}

The service type <http://purl.org/ontology/dso#Remote>, abbreviated as
`remote`, indicates that an item is made accessible outside of the institution
or department without having to visit its place. This primarily applies to
online usage of digital documents but it also subsumes other kinds of delivery
such as mail.  

Services of this type SHOULD be restricted by an explicit [limitation] if
access is not possible in digital form ([PhysicalDelivery]) or from anywhere
(for instance [NoForeignCountry]).

DAIA servers SHOULD always include field `delay` with [available] services of
type remote. DAIA clients MAY take a very small duration in field `delay` as
indicator for direct access to a digital document, unless teleportation has
been invented.

### interloan {.unnumbered}

The service type <http://purl.org/ontology/dso#Interloan>, abbreviated as
`interloan`, indicates that an item is made accessible mediated by another
institution (interlibrary loan or comparable service). The item or a copy is
first sent from a supplying institution to a requesting institution and made
accessible afterwards.

### openaccess {.unnumbered}

The service type <http://purl.org/ontology/dso#Openaccess>, abbreviated as
`openaccess`, indicates that an item is accessible freely and without any
restrictions at a public URL.

This service type subsumes *gratis open access* (online access free of charge)
and *libre open access* (online access free of charge plus various additional
usage rights). This service type MUST NOT be used if access requires some kind
of login or registration, if access is restricted to selected IPs or if similar
limitations apply (use service type [remote] instead). 


## Availability

[availability]: #availability

### available {.unnumbered}

An **available** service is a JSON object with one REQUIRED and three OPTIONAL
fields:

name        type                       description
----------- ----------------- -------- --------------------------------------------------
service     service           REQUIRED the type of [service] being available
href        URL               OPTIONAL a link required to perform, register or reserve the service
delay       duration          OPTIONAL estimated delay (if given).
limitation  array of [entity] OPTIONAL more specific [limitations] of the service
----------- ----------------- -------- --------------------------------------------------

If field `delay` is missing, then there is probably no significant delay.  If
field `delay` is `unknown`, then there is probably a delay but its duration is
unknown.

If field `href` is given, a DAIA client MUST assume that this link is required
to perform the service. If field `href` is not given, a DAIA client SHOULD
assume that the service can be used without further information.

<div class="example">
Directly available, e.g. documents in open stacks or pickup area:

```json
{ "service": "presentation" }
{ "service": "loan" }
```

Available by interlibrary loan by standard method:

```json
{ "service": "interloan" }
```

Available after request, for instance submission of form at the given URL:

```json
{ "service": "presentation", "href": "http://example.org/request" }
{ "service": "loan",         "href": "http://example.org/request" }
{ "service": "interloan",    "href": "http://example.org/request" }
```

Available online from everywhere at the given URL:

```json
{ "service": "openaccess", "href": "http://example.org/request" }
```

Available online from everywhere at unknown URL:

```json
{ "service": "openaccess" }
```
</div>

### unavailable {.unnumbered}

An **unavailable** service is a JSON object with one REQUIRED and four OPTIONAL
fields:

name        type                       description
----------- ----------------- -------- --------------------------------------------------
service     service           REQUIRED the type of [service] being unavailable
href        URL               OPTIONAL a link required to perform, register or reserve the service
expected    anydate           OPTIONAL expected date when the service will be available again
queue       count             OPTIONAL number of waiting requests for this service
limitation  array of [entity] OPTIONAL more specific [limitations] of the service
----------- ----------------- -------- --------------------------------------------------

If field `expected` is `unknown` then the service will probably be available at
some time in the future. If field `expected` is not is given, it is not known
when or whether the service will be available again.

If field `href` is given, a DAIA client MUST assume that this link is required
to perform the service as soon at is is available again. If field `href` is not
given, a DAIA client SHOULD NOT assume whether additional information is needed
once the service is available again.

<div class="example">

The following [item] is

* available for service type *presentation* with a delay of two hours
* available for an additional service type identified by URI
  `http://example.org/digitize` that can be requested with a given link.
* unavailable for service type `loan` for probably infinite time

`examples/service-1.json`{.include .codeblock .json}
</div>

<div class="note">
An item can have multiple services of the same service type as long as
[integrity rules] are not violated. For instance the following item
is available for presentation without limitations but expected to be
available without limitation at a given date:

```json
{
  "available": [ {
    "service": "presentation",
    "limitation": [ { "id": "http://example.org/restricted" } ]
  } ],
  "unavailable": [ {
    "service": "presentation",
    "expected": "2017-03-07"
  } ]
}
```
</div>


## Limitations

[limitations]: #limitations
[limitation]: #limitations

A [service] can be restricted by **limitations**, given as [entity]. It is
RECOMMENDED to identity types of service limitations with an URI (field `id`)
but unspecified, free-text limitations (field `content`) are possible as well.

DAIA clients are not required to understand limitation types so they MAY map
all limitations to the same "unknown" kind of limitation. DAIA servers SHOULD
NOT use limitations to transport arbitrary messages that do not correspond to
real impairments of a service.  The following limitation types are RECOMMENDED
to be used by DAIA servers and to be understood by DAIA clients if applicable:

local name          applicable service types
------------------- ---------------------------------------------
[ApprovalRequired]  [presentation], [loan], [remote], [interloan]
[ShortLoan]         [loan], [remote], [interloan]
[Stationary]        [presentation], [remote], [interloan]
[PhysicalDelivery]  [remote], [interloan]
[PartialDelivery]   [remote], [interloan]
[NoForeignCountry]  [remote], [interloan]
[PhysicalInterloan] [interloan]

In addition, limitation types with base URI <http://creativecommons.org/license/> 
are [applicable with service type openaccess](#openaccess-limitation-types).

<div class="note">
If a DAIA server supports both limitation types [PhysicalDelivery] and
[Stationary], the type of delivery with service types [remote] and 
[interloan] can be inferred from (non)existence of this limitations:

* [PhysicalDelivery] and [Stationary] $\Rightarrow$ physical copy
* [PhysicalDelivery] only $\Rightarrow$ physical original
* [Stationary] only $\Rightarrow$ digital copy of a physical item
* none of both $\Rightarrow$ digital copy

If a DAIA server supports both limitation types [PhysicalInterloan] and
[Stationary], the type of transport from supplying institution to requesting
instiution with service type [interloan] can be inferred from (non)existence of
this limitations:

* [PhysicalInterloan] and [Stationary] $\Rightarrow$ physical copy
* [PhysicalInterloan] only $\Rightarrow$ physical original
* [Stationary] only $\Rightarrow$ digital copy of a physical item
* none of both $\Rightarrow$ digital copy
</div>

### ApprovalRequired {.unnumbered}

uri
  : <http://purl.org/ontology/dso#ApprovalRequired> 

applicable
  : service types [presentation], [loan], [remote], and [interloan]

description
  : a special permission, such as a written justification of research interest
    or an exception permit is required.

### ShortLoan {.unnumbered}

uri
  : <http://purl.org/ontology/dso#ShortLoan> 

applicable
  : service types [loan], [remote], and [interloan]

description
  :  the period for lending or accessing an item is shorter than usual.

### Stationary {.unnumbered}

uri
  : <http://purl.org/ontology/dso#Stationary>

applicable
  : physical items with service types [loan], [remote], and [interloan]

description
  : the item can only be used at its current location.

With service type [presentation] this limitation type implies the item cannot
be moved within the institution but stays at its current location ([item] field
`storage`). This applies for instance to museum objects which are not moved to
a special "reading room" like other non-lending holdings. 

With service type [remote] and [interloan] this limitation type implies that the
item is physical but only provided as physical or digital copy.

### PhysicalDelivery {.unnumbered}

uri
  : <http://purl.org/ontology/dso#PhysicalDelivery>

applicable
  : service types [remote] and [interloan] 

description
  : access to the item not supplied in digital but in physical form.

With service type [remote] this limitation implies that the item or a physical
copy is sent to the patron.

With service type [interloan] this limitation implies that the receiving
library is not allowed to hand out a digital copy to the patron. The transport
from giving to receiving library may still be digital unless a limitation
of type [PhysicalInterloan] is also given.

This limitation type does not imply that the original item is physical.

### PartialDelivery {.unnumbered}

uri
  : <http://purl.org/ontology/dso#PhysicalDelivery>

applicable
  : service types [remote] and [interloan] 

description
  : the item is not handed out to the patron as full original but as partial copy.

<div class="note">
A typical use case of this limitation type is requesting library staff to make
a photocopy or scan of a part (chapter or article) of an item, which will them
be emailed or delivered to the user. If the part can be identified, it may make
more sense to use field `part` of [item]. The following example illustrates the
difference.

In the first case item `example:section:1` contains a defined part of
`example:document`.  This part is provided to the patron:

~~~json
{ 
  "id": "example:document",
  "items": [ 
    {
      "id": "example:section:1",
      "part": "narrower",
      "available": {
        "service": "remote" 
      }
    }
  ]
}
~~~

In the second case item `example:all-sections` contains all of
`example:document` but the patron only gets an (unspecified) part of it:

~~~json
{ 
  "id": "example:document",
  "items": [ 
    {
      "id": "example:all-sections",
      "available": {
        "service": "remote",
        "limitation": [
          { "id": "http://purl.org/ontology/dso#PartialDelivery" }
        ]
      }
    }
  ]
}
~~~
</div>

### NoForeignCountry {.unnumbered}

uri
  : <http://purl.org/ontology/dso#NoForeignCountry>

applicable
  : service types [remote] and [interloan] 

description
  : the item is only made available to patrons ([remote]) or requesting 
    institutions ([interloan]) in the same country as the supplying institution.

<div class="note">
This specification does not define what "same country" actually means because this
is a legally and politically difficult issue.
</div>

<div class="example">
An Item available for interlibrary loan only as paper copy within the same
country as the giving institution.

```json
{
  "available": [ {
    "service": "interloan",
    "limitation": [ {
      "id": "http://purl.org/ontology/dso#PhysicalDelivery",
      "content": "Only paper copy to patron"
    }, {
      "id": "http://purl.org/ontology/dso#NoForeignCountry",
      "content": "Only domestic loans"
    } ]
  } ]
}
```
</div>

### PhysicalInterloan {.unnumbered}

uri
  : <http://purl.org/ontology/dso#PhysicalInterloan>

applicable
  : service type [interloan] 

description
  : the item is sent from supplying institution to requesting institution in physical form.

<div class="note">
Physical transport is the default in traditional interlibrary loan of physical books,
so existence of this limitation type does not necessarily mean an obstacle.
</div>

### openaccess limitation types {.unnumbered}

uri
  : all starting with <http://creativecommons.org/license/>

applicable
  : service type [openaccess]

description
  : tell a specific Creative Commons License of the copy. In contrast to
    other service types this is not a limitation of access but a limitation 
    of usage.

<div class="example">
An Open Access journal article licensed under CC-BY 3.0 (US):

```json
{
  "about": "Editorial Introduction: The Code4Lib Journal Experiment, Rejection Rates, and Peer Review", 
  "available": [ { 
    "service": "openaccess",
    "href": "http://journal.code4lib.org/articles/3277",
    "limitation": [ {
      "id": "http://creativecommons.org/licenses/by/3.0/us/",
      "href": "https://creativecommons.org/licenses/by/3.0/us/",
      "content": "CC-BY 3.0 US"
    } ]
  } ]
}
```

A public domain audio book:

```json
{
  "about": "Uncle Tom's Cabin",
  "available": [ {
    "service": "openaccess",
    "href": "https://archive.org/details/uncle_toms_cabin_librivox",
    "limitation": [ {
      "id": "http://creativecommons.org/licenses/publicdomain/",
      "href": "https://creativecommons.org/licenses/publicdomain/",
      "content": "Public Domain"
    } ]
  } ]
}
```
</div>

## Chronology

A **chronology** is a JSON object with one OPTIONAL field:

name    type                description
------- ------- ----------- ------------------------------------------------------
about   string  OPTIONAL    human-readble summary of the chronology or enumeration
------- ------- ----------- ------------------------------------------------------

A chronology specifies the extend of a partitioned [item] such as a serial in
terms of time spans, volumes, and issues. A later version of DAIA specification
will define addition fields to express this information in structured form.
DAIA clients SHOULD therefore ignore unknown fields in a chronology object
until they can refer to a later version of DAIA.

Item field `part` SHOULD be set to `narrower` if a chronology is given and the
chronology does not cover the full extent of the document (for instance not all
issues of a journal).

<div class="example">

An itemChronology of an item with cronology volume 1 (1920) until volume 19 (1939),
volume 21 (1941), and volume 36 (1956) since the most current volume:

`examples/chronology-1.json`{.include .codeblock .json}

First issue of *Philosophical Transactions* the first English scientific
journal, in response to availability of the full journal until its first rename
(1665–1678):

`examples/response-7.json`{.include .codeblock .json}

</div>

## Integrity rules

[integrity rules]: #integrity-rules

DAIA data model is specified using JSON but it can also be expressed in other
data structuring languages such as RDF. For this reason and to avoid misleading
data instances, the following **integrity rules** MUST be met in a [DAIA
Response]:

1. Documents and items are unique: all [Documents] and [Items] MUST have unique
   values in field `id`, if given. As exception a document with a single item
   that does not have field `part` set MAY share the same `id` with its item
   (for instance a unique physical item without dedicated document identifier).

2. Institution is is disjoint to departments and storages within the same 
   [DAIA response]: The value of field `institution.id` SHOULD NOT occur as
   `id` of another entity (`storage`, `department`, and `limitation`).

4. [Limitations] (field `id`) MUST be disjoint with other entities
   (`institution`, `storage`, and `department`).

5. Storages are subordinated to departments: The value of field `id` in [Item]
   entity `storage` MUST NOT be equal to field `id` of entity `department` of
   the same item.

6. An [Item] MUST NOT have an [available] service and an [unavailable] service
   with the same service type (field `service`) and equal values in field
   `limitation`. Two limitation entities are equal if thei share the same field
   `id` or if they both have no `id` and same field values `href` and `content`.

<div class="example">
The URI <http://example.org/123> in the following example is used multiple times
so the JSON document is no valid DAIA Response:

```json
{
  "document": [
    { "id": "http://example.org/123" },
    { "id": "http://example.org/123",
      "item": [ { "id": "http://example.org/123" } ] }
  ]
}
```

The same entity, however can occur as storage in one item and as department in
*another* item. For instance the following document is valid:

```json
{
  "document": [ {
    "id": "http://example.org/123",
    "item": [ {
      "department": "http://example.org/archive"
    },{
      "department": "http://example.org/main",
      "storage": "http://example.org/archive"
    } ]
}
```

This is not allowed because the same service type and limitation (none) is both
available and unavailable.

```json
{
  "available": [ { "service": "presentation", "href": "http://example.org/request" } ],
  "unavailable": [ { "service": "presentation" } ]
}
```
</div>

# Request and response

A DAIA server is queried via HTTP or HTTPS GET request. HTTP methods HEAD and
OPTIONS SHOULD also be supported.

A DAIA server MUST always return a [DAIA Response] or an [error response] for
HTTP GET requests.

The URL to query a DAIA server stripped from all query parameters is called
its **base URL**. It is RECOMMENDED to use a HTTPS base URL.

## Query parameters

[query id]: #query-parameters
[query parameter]: #query-parameters
[request identifier]: #query-parameters
[request identifiers]: #query-parameters
[base URL]: #query-parameters

A DAIA server MUST respect following query parameters:

id
  : query id with one or multiple **request identifiers** of documents or items.

format
  : set to `json`. If this parameter is missing or not set to `json`, a DAIA server
    SHOULD sent an [error response] with HTTP status code 422 (invalid request). For
    backwards compatibility with previous implementations, a DAIA server MAY also
    response with HTTP status code 200 and with an arbitrary document (HTML, XML...)
    if no `format` parameter was given or if its value was not `json`.

callback
  : a JavaScript callback method name to return JSONP instead of JSON. The callback MUST
    only contain alphanumeric characters and underscores.

patron
  : a patron identifier for [patron-specific availability].

patron-type
  : a patron identifier for [patron-specific availability].

access_token
  : an [access token] for authentication.
    A DAIA client MUST use HTTPS when sending access tokens.

suppress_response_codes
  : if this parameter is present, all responses MUST be returned with a 200 OK status code,
    even an [error response]. Support of this parameter is OPTIONAL.


### Processing the query id {.unnumbered}

If the query id does not includes a vertical bar ("`|`", Unicode character
U+007C), a DAIA server MUST use its value as request identifier. Otherwise a
DAIA server MUST split the query id at vertical bars into multiple request
identifiers. A DAIA server MAY sent an [error response] with HTTP status code
422 if it cannot handle multiple request identifiers or if the query id is too
long.  A DAIA server MAY choose to only process a subset of multiple request
identifiers: in this case the response MUST include a `Link` [response header]
with a new request URL that includes a query id with all remaining request
identifiers, joined with vertical bars, and additional known query parameters,
if given.

<div class="example">
A DAIA server with base URL `https://example.org/` is queried with a query id
that contains five request identifiers: `x:a`, `x:b`, `x:c`, `x:d`, and `x:e`.

```
GET /?id=x:a%7Cx:b%7Cx:c%7Cx:d%7Cx:e&format=json HTTP/1.1
Host: example.org
User-Agent: MyDAIAClient/1.0
Accept: application/json
```

The server only processes the first three request identifiers and finds a
matching document for one of them (`x:b`). The remaining request identifiers
`x:d` and `x:e` are included in a new request URL:

```
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Content-Language: en
X-DAIA-Version: 1.0.0
Link: <https://example.org/?id=x:d%7Cx:e&format=json>; rel="next"
```

`examples/response-3.json`{.include .codeblock .json}
</div>

A DAIA client MUST escape vertical bars in the query id as `%7C`, as requested
by [RFC 3986]. As many HTTP clients don't automatically escape the vertical bar,
a DAIA server SHOULD also accept the unescaped character (byte code 124).

<div class="example">
A DAIA server SHOULD accept this queries equivalently with three request 
identifiers `x:a`, `x:b`, and `x:c`:

    ?format=json&id=x:a%7Cx:b%7Cx:c
    ?format=json&id=x:a%7Cx:b|x:c
    ?format=json&id=x:a|x:b%7Cx:c
    ?format=json&id=x:a|x:b|x:c
</div>

<div class="note">
The mapping from query id to zero or more document or item identifiers is
done in two steps:

> query id $\rightarrow$ request identifier(s) $\rightarrow$ document/item identifier(s)

Request identifiers are returned in field `document.*.id` and/or
`document.*.requested` of a [DAIA response] if the DAIA server was able to find
a corresponding document.
</div>

## Request headers

[request header]: #request-headers

A DAIA client SHOULD sent the following HTTP request headers:

User-Agent
  : with an appropriate client name and version number.

Accept
  : with the value `application/json`.

A DAIA client MAY sent the following HTTP request headers:

Accept-Language
  : to indicate preferred languages of human-readable response fields
    (`content`, `about`, `error_description`).

Authorization
  : to provide an OAuth 2 Bearer token for [authentication].

For OPTIONS preflight requests of Cross-Origin Resource Sharing (CORS) a DAIA
client MUST include the following HTTP request headers:

Origin
  : where the cross-origin request originates from.

Access-Control-Request-Method
  : the HTTP verb `GET`.

Access-Control-Request-Headers
  : the value `Authorization` if access tokens are sent as HTTP headers.

Note that DAIA clients do not need to respect CORS rules. CORS preflight
requests in browsers can be avoided by omitting the request headers `Accept`
and `Authorization`.

## Response headers

[response header]: #response-headers

A DAIA server SHOULD sent the following HTTP response headers with every [DAIA Response]:

Content-Language
  : to indicate the language of human-readable response fields
    (`content`, `about`, `error_description`).

Access-Control-Allow-Origin
  : to allow Cross-Origin Resource Sharing, this header SHOULD be set to `*`.

Link
  : URL of a [DAIA profile] document with [RFC 5988] relation type `profile`.
    Also a [request URL](#request-and-response) with unprocessed request
    identifiers (if given) and relation type `next`.

A DAIA server MUST sent the following HTTP response headers:

Content-Type
  : the value `application/json` or `application/json; charset=utf-8` for JSON response;
    the value `application/javascript` or `application/javascript; charset=utf-8` for JSONP response.

X-DAIA-Version
  : the version of DAIA specification which the server was checked against.

Access-Control-Allow-Headers
  : In response to an OPTIONS request this header MUST include the value `Content-Type`
    and, if [authentication] is supported, the value `Authorization`.

## Error responses

[error response]: #error-responses

A DAIA server SHOULD use HTTP status codes to indicate server errors and client
request errors. An error response SHOULD include a JSON object with the
following fields:

error
  : alphanumeric error code.

code
  : HTTP status code.

error_description
  : human-readable error description (OPTIONAL).

error_uri
  : human-readable web page about the error (OPTIONAL).

The following error responses are expected:

 error               code  description
-------------------- ---- -----------------------------------------------------------------------
 invalid_request      400  Malformed request, for instance malformed HTTP request headers
 invalid_grant        401  The [access token] was missing, invalid, or expired
 insufficient_scope   403  The access token was accepted but it lacks permission for the request
 invalid_request      405  Unexpected HTTP verb
 invalid_request      422  Missing or invalid query parameters
 internal_error       500  An unexpected error occurred, such as a serious bug
 not_implemented      501  Access token was sent but no support of [patron-specific availability]
 bad_gateway          502  The request couldn't be serviced because of a backend failure
 service_unavailable  503  The request couldn't be serviced because of a temporary failure
 gateway_timeout      504  The request couldn't be serviced because of a backend failure
-------------------- ----- ------------------------------------------------------------------------

A DAIA server SHOULD never return a HTTP 404 error if queried at its [base
URL]. In particular a DAIA server MUST NOT respond with a HTTP 404 status code
for missing or unknown [request identifiers](#query-parameters).

## Patron-specific availability

[patron-specific availability]: #patron-specific-availability

A DAIA server MAY support patron-specific availability with the [query
parameter] `patron` and/or `patron-type`. The `patron` parameter can be used to
refer to a particular patron and the `patron-type` parameter can be used to
refer to a particular type of patrons.

Definiton of patron types is out of the scope of this specification. It is
RECOMMENDED to use URIs for identification of both patrons and patron types.

<div class="note">
The Patrons Account Information API (PAIA) defines an API to access patron
accounts. If both PAIA and DAIA are provided to a given library systems the
patron identifiers and patron types SHOULD be shared among both APIs.
</div>

A DAIA client SHOULD NOT include both parameters in the same request. A DAIA
server SHOULD return an [error response] status 422 (invalid request) if both
are given or if given values are unknown or invalid. A DAIA server SHOULD
return an [error response] status 501 (not supported) if it does not support
patron-specific availability for `patron` or `patron-type` respectively.

Patron-specific availability SHOULD be combined with [authentication].

<div class="example">
A document with id `doc:rare` is not allowed to be lend by normal students
but allowed for patrons of type <http://example.org/type/researcher>:

```
http://example.org/?format=json&id=doc:rare&patron-type=http%3A%2F%2Fexample.org%2Ftype%2Fstudent
```

`examples/response-4.json`{.include .codeblock .json}

```
http://example.org/?format=json&id=doc:rare&patron-type=http%3A%2F%2Fexample.org%2Ftype%2Fresearcher
```

`examples/response-5.json`{.include .codeblock .json}

If no patron type has been specified, the special loan condition can be expressed as limitation:

```
http://example.org/?format=json&id=doc:rare
```

`examples/response-6.json`{.include .codeblock .json}
</div>

## Authentication

[access token]: #authentication
[authentication]: #authentication

A DAIA server MAY support authentfication via OAuth 2.0 bearer tokens ([RFC
6750]). Access tokens can be provided either as URL query parameter
`access_token` or in the HTTP [request header] `Authorization`.

A DAIA server that supports authentication, MUST also support HTTP OPTIONS
requests for CORS.

DAIA server and client MUST use HTTPS when sending and receiving access tokens.

Distribution of access tokens is out of the scope of this specification.

When also using PAIA it is RECOMMENDED to issue access tokens via PAIA auth and
add a scope named `read_availability` for authentificated access to a DAIA
server.

<div class="example">
The following requests both include the same access token for authentication.

```
GET /?format=json&id=some:doc HTTP/1.1
Host: example.org
User-Agent: MyDAIAClient/1.0
Accept: application/json
Authorization: Bearer vF9dft4qmT
```

```
GET /?format=json&id=some:doc&access_token=vF9dft4qmT HTTP/1.1
Host: example.org
User-Agent: MyDAIAClient/1.0
Accept: application/json
```
</div>

## Profiles

[DAIA profile]: #profiles

A DAIA Server SHOULD supply a **profile** in form of a JSON document. The
DAIA profile MUST be referred to in a HTTP Link header as part of [Response
headers].

<div class="example">
HTTP response headers including a link to a DAIA profile:

~~~
HTTP/1.1 200 OK
Content-Language: en
Access-Control-Allow-Origin: *
Link: <https://example.org/profile.json>; rel="profile"
Content-Type: application/json; charset=utf-8
X-DAIA-Version: 1.0.0
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Methods: GET, HEAD, OPTIONS
~~~

</div>

<div class="note">
The format a DAIA profile has not been specified yet. See
<https://github.com/gbv/daia/issues/22> for discussion. 
</div>

# References

## Normative References

* Berners-Lee, T., Fielding R., Masinter L. 2005. 
  “RFC 3986: Uniform Resource Identifiers (URI): Generic Syntax”.
  <http://tools.ietf.org/html/rfc3986>.

* Biron, P. V., Malhotra, A. 2004. “XML Schema Part 2: Datatypes Second Edition”.
  <http://www.w3.org/TR/xmlschema-2/>.

* Bradner, S. 1997. “RFC 2119: Key words for use in RFCs to Indicate Requirement Levels”.
  <http://tools.ietf.org/html/rfc2119>.

* Crockford, D. 2006. “RFC 6427: The application/json Media Type for JavaScript Object Notation (JSON)”.
  <http://tools.ietf.org/html/rfc4627>.

* Fielding, R. 1999. “RFC 2616: Hypertext Transfer Protocol”.
  <http://tools.ietf.org/html/rfc2616>.

* Jones, M. and Hardt, D. 2012. “RFC 6750: The OAuth 2.0 Authorization Framework: Bearer Token Usage”.
  <http://tools.ietf.org/html/rfc6750>.

* Nottingham, M. 2010. “RFC 5988: Web Linking”.
  <http://tools.ietf.org/html/rfc5988>.

* van Kesteren, A. 2014. “Cross-Origin Resource Sharing”
  <http://www.w3.org/TR/cors/>.

## Informal References

* Davis, M. and Whistler, K.: “Unicode Normalization Forms”.
  Unicode Standard Annex #15. <http://www.unicode.org/reports/tr15/>.

* Galiegue, F. and Zyp, K. 2013: “JSON Schema v4”.
  <http://json-schema.org/latest/json-schema-core.html>.

* Sporny, M. et al., 2014: “JSON-LD 1.0”.
  <https://www.w3.org/TR/json-ld/>

* Voß, J. 2015. “Patrons Account Information API (PAIA)”
  <http://gbv.github.io/paia/>.

* Voß, J. 2015. “ng-daia”.
  <http://gbv.github.io/ng-daia/>.

[RFC 2119]: http://tools.ietf.org/html/rfc2119
[RFC 3986]: http://tools.ietf.org/html/rfc3986
[RFC 5988]: http://tools.ietf.org/html/rfc5988
[RFC 6750]: http://tools.ietf.org/html/rfc6750

## Revision history

This is version **{VERSION}** of DAIA specification, last modified at
{GIT_REVISION_DATE} with revision {GIT_REVISION_HASH}.

Version numbers follow [Semantic Versioning](http://semver.org/): each number
consists of three numbers, optionally followed by `+` and a suffix:

* The major version (first number) is increased if changes require
  a modification of DAIA clients
* The minor version (second number) is increased if changes require
  a modification of DAIA servers
* The patch version (third number) is increased for backwards compatible
  fixes or extensions, such as the introduction of new optional fields
* The optional suffix indicates informal changes in documentation

Before version 1.0.0 the patch version was used as minor version.

### Releases {.unnumbered}

Releases with functional changes are tagged with a version number and
included at <https://github.com/gbv/daia/releases> with release notes.

#### 0.9.10 (2017-02-14) {.unnumbered}

* Make item id and entity id RECOMMENDED (#33)
* Add OPTIONAL response fields `$schema` and `@context`
* Add OPTIONAL item field `chronology`
* Update JSON Schema

#### 0.9.9 (2016-02-26) {.unnumbered}

* Make support of Link response header mandatory and add profile
* Moved and extended recommended limitation types to main part
* Renamed limitation type NoDigitalTransfer to PhysicalInterloan
* Clarify service type remote is primarily digital
* Add required response header `Access-Control-Allow-Headers`

#### 0.9.8 (2016-01-08) {.unnumbered}

* Added service type remote
* Improved description of service types and limitation types

#### 0.9.7 (2015-12-18) {.unnumbered}

* Recommend limitations for more service types

#### 0.9.6 (2015-12-02) {.unnumbered}

* Require escaping of vertical bar in query id
* Better explain openaccess service and add recommended license limitations

#### 0.9.5 (2015-10-23) {.unnumbered}

* Clarified meaning of href field in services (#13)
* Fixed meaning of field expected with value unknown

#### 0.9.3 (2015-10-13) {.unnumbered}

* Added JSON Schema as non-normative part
* Moved DAIA Simple to non-normative appendix

#### 0.9.3 (2015-10-12) {.unnumbered}

* Added integrity rules
* Made service field required

#### 0.9.2 (2015-09-28) {.unnumbered}

* Dropped fields `message`, `version`, `schema`
* Made `format` query parameter mandatory
* Removed DAIA/XML and DAIA/RDF
* Specified processing of multiple request identifiers
* Added field requested to map request identifiers to documents
* Added authentication
* Added patron-specific availability
* Added CORS and HTTP OPTIONS
* Added field about to document and item
* Entities must at least have one field (id, content, and/or href)

#### 0.8 (2015) {.unnumbered}

* Added DAIA Simple

#### 0.5 (2009) {.unnumbered}

* First specification

### Recent changes {.unnumbered}

{GIT_CHANGES}

# Appendix

The following parts are non-normative.

## DAIA Simple

**DAIA Simple** is simplified alternative to [DAIA Response] format for a
particular document limited to a typical use case of availability information.
A DAIA client could map DAIA Response to DAIA Simple or a DAIA server could
directly support DAIA Simple as additional response when [query parameter]
"format" is set to `simple`.

A DAIA Simple object is a plain JSON object with the following
fields, based on [simple data types](#simple-data-types):

name       type     description
---------- -------- ---------------------------------------------------------------------------
service    string   most relevant [service](#services) (one of `openaccess`, `loan`, `remote`, `presentation`, `none`)
available  boolean  whether the service is available or not
delay      duration expected delay (only relevant if `available` is `true`)
expected   anydate  expected date of availability (only relevant if `available` is `false`)
queue      count    length of waiting queue (only relevant if `available` is `false`)
href       URL      OPTIONAL URL to perform or request the service
limitation string   OPTIONAL string describing an additional limitation
---------- -------- ---------------------------------------------------------------------------

<div class="example">
```json
{ "service": "loan", "available": true }
{ "service": "loan", "available": false, "expected": "2014-12-07" }
{ "service": "presentation", "available": true }
{ "service": "openaccess", "available": true, "href": "http://dx.doi.org/10.1901%2Fjaba.1974.7-497a" }
```
</div>

<div class="note">
The DAIA client [ng-daia] implements a possible mapping of DAIA Response to
DAIA Simple and a possible HTML display of DAIA Response and DAIA Simple. Try
the [demo page](https://gbv.github.io/ng-daia/demo/) to get DAIA Simple from
DAIA Response format.
</div>

[ng-daia]: http://gbv.github.io/ng-daia/


## JSON Schema

[JSON Schema]: #json-schema

The following JSON Schema [`daia.schema.json`](daia.schema.json) can be used
to validate [DAIA Response] format without [integrity rules].

`daia-schema/daia.schema.json`{.include .codeblock .json}

# Acknowledgements

Thanks for contributions to DAIA specification from Uwe Reh, David Maus, Oliver
Goldschmidt, Jan Frederik Maas, Jürgen Hofmann, Anne Christensen, André
Lahmann, Ross Singer, Jonathan Rochkind, and Christian Hauschke among others.

----

This version: <http://gbv.github.io/daia/{CURRENT_VERSION}.html> ({CURRENT_TIMESTAMP})\
Latest version: <http://gbv.github.io/daia/>

Created with [makespec](http://jakobib.github.io/makespec/)
