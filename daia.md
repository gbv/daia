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
  : An URI or a string with one of values `presentation`, `loan`, `interloan`, and
    `openaccess`. DAIA clients SHOULD ignore other non-URI values.
entity
  : A JSON object with the following OPTIONAL fields:

    name    type    description
    ------- ------- --------------------------------------------------------
    id      URI     globally unique identifier of the entity
    href    URL     web page about the entity
    content string  human-readable label, title or description of the entity
    ------- ------- --------------------------------------------------------

    At least one of this fields MUST be given.

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

A **DAIA Response** is a JSON object with three OPTIONAL fields:

name        type                 description
----------- -------------------- ----------------------------------------------------------------------
institution entity               institution that grants or knows about services and their availability
document    array of [documents] documents matching the processed request identifiers
timestamp   datetime             time the DAIA Response was generated
----------- -------------------- ----------------------------------------------------------------------

A DAIA Response sent by a DAIA server in response to a request MUST only
contain [documents] matching queried [request identifiers]. A document matches
a given request identifier if the request identifier is repeated in document
field `id`, `requested`, or both. A DAIA Response MAY contain multiple
documents that match the esame request identifier.

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

## Documents

[documents]: #documents

A **document** is a JSON object with one REQUIRED and four OPTIONAL fields:

name      type                      description
--------- ---------------- -------- ------------------------------------------
id        URI              REQUIRED globally unique identifier of the document
requested string           OPTIONAL request identifier matching this document
href      URL              OPTIONAL web page about the document
about     string           OPTIONAL human-readable description of the document
item      array of [items] OPTIONAL set of instances or copies of the document
--------- ---------------- -------- ------------------------------------------

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

An **item** is a JSON object with nine OPTIONAL fields:

name        type                            description
----------- ---------------------- -------- ---------------------------------------------------------------
id          URI                    OPTIONAL globally unique identifier of the item
href        URL                    OPTIONAL web page about the item
part        string                 OPTIONAL whether and how the item is partial
label       string                 OPTIONAL call number or similar item label for finding or identification
about       string                 OPTIONAL human-readable description of the item
department  entity                 OPTIONAL an administrative sub-entitity of the institution
storage     entity                 OPTIONAL a physical location of the item (stacks, floor etc.)
available   array of [available]   OPTIONAL set of available [services]
unavailable array of [unavailable] OPTIONAL set of unavailable [services]
----------- ---------------------- -------- ------------------------------------------------------

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
the the institution and for loan under special conditions but it is not
available as Open Access.

`examples/response-2.json`{.include .codeblock .json}
</div>

## Services

[service]: #services
[services]: #services

A service is something that an item is currently accessible or unaccessible for
([item] fields `available` and `unavailable`). Each service has a **service
type** to define what can be done with a given item. DAIA defines the following
service types:

presentation
  : the item is accessible within the institution (in their rooms, in their intranet).
loan
  : the item is accessible outside of the institution (by lending or online access) 
    for a limited time.
openaccess
  : the item is accessible freely and without any restrictions via a public URL.
    This service type subsumes *gratis open access* (online access free of charge)
    and *libre open access* (online access free of charge plus various additional
    usage rights). This service type MUST NOT be used if access requires some kind
    of login or registration, if access is restricted to selected IPs or if similar
    limitations apply. See the appendix on [service limitations] for possible 
    specification of further usage rights.
interloan
  : the item is accessible mediated by another institution.

An item can further be available for an unspecified service type and for
additional service types identified by URIs. The following URIs can be used
equivalent to DAIA services:

* <http://purl.org/ontology/dso#Presentation> = presentation
* <http://purl.org/ontology/dso#Loan> = loan
* <http://purl.org/ontology/dso#Openaccess> = openaccess
* <http://purl.org/ontology/dso#Interloan> = interloan

### available {.unnumbered}

An **available** service is a JSON object with one REQUIRED and three OPTIONAL
fields:

name        type                     description
----------- --------------- -------- --------------------------------------------------
service     [service]       REQUIRED the type of service being available
href        URL             OPTIONAL a link required to perform, register or reserve the service
delay       duration        OPTIONAL estimated delay (if given).
limitation  array of entity OPTIONAL more specific limitations of the service
----------- --------------- -------- --------------------------------------------------

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

name        type                     description
----------- --------------- -------- --------------------------------------------------
service     service         REQUIRED the type of service being unavailable
href        URL             OPTIONAL a link required to perform, register or reserve the service
expected    anydate         OPTIONAL expected date when the service will be available again
queue       count           OPTIONAL number of waiting requests for this service
limitation  array of entity OPTIONAL more specific limitations of the service
----------- --------------- -------- --------------------------------------------------

If field `expected` is `unknown` then the service will probably be available at
some time in the future. If field `expected` is not is given, it is not known
when or whether the service will be available again.

If field `href` is given, a DAIA client MUST assume that this link is required
to perform the service as soon at is is available again. If field `href` is not
given, a DAIA client SHOULD NOT assume whether additional information is needed
once the service is available again.

<div class="example">

The following [item] is

* available for service type `presentation` with a delay of two hours
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

## Integrity rules

[integrity rules]: #integrity-rules

DAIA data model is specified using JSON but it can also be expressed in other
data structuring languages such as RDF. For this reason and to avoid misleading
data instances, the following **integrity rules** MUST be met in a [DAIA
Response]:

1. Documents and items are unique: all [Documents] and [Items] MUST have unique
   values in field "id".

2. Institution is disjoint to departments and storages: The value of field "id"
   in [DAIA Response] entity "institution" MUST NOT occur as "id" of another entity.

3. Storages are subordinated to departments: The value of field "id" in [Item]
   entity "storage" MUST NOT be equal to field "id" of entity "department" of
   the same item.

4. An [Item] MUST NOT have an [available] service and an [unavailable] service
   with the same service type (field "service") and equal values in field
   "limitation". Two limitation entities are equal if thei share the same field
   "id" or if they both have no "id" and same field values "href" and "content".

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
    if no "format" parameter was given or if its value was not `json`.
callback
  : a JavaScript callback method name to return JSONP instead of JSON. The callback MUST
    only contain alphanumeric characters and underscores.
patron
  : a patron identifier for [patron-specific availability].
patron-type
  : a patron identifier for [patron-specific availability].
access_token
  : an [access token] for authentification.
    A DAIA client MUST use HTTPS when sending access tokens.
suppress_response_codes
  : if this parameter is present, all responses MUST be returned with a 200 OK status code,
    even an [error response]. Support of this parameter is OPTIONAL.

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
  : to provide an OAuth 2 Bearer token for [authentification].

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
Content-Type
  : the value `application/json` or `application/json; charset=utf-8` for JSON response;
    the value `application/javascript` or `application/javascript; charset=utf-8` for JSONP response.
X-DAIA-Version
  : the version of DAIA specification which the server was checked against.
Link
  : to refer to another [request URL](#request-and-response) with unprocessed request
    identifiers and [RFC 5988] relation type `next`.

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

Patron-specific availability SHOULD be combined with [authentification].

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

## Authentification

[access token]: #authentification
[authentification]: #authentification

A DAIA server MAY support authentfication via OAuth 2.0 bearer tokens ([RFC
6750]). Access tokens can be provided either as URL query parameter
`access_token` or in the HTTP [request header] `Authorization`.

A DAIA server that supports authentification, MUST also support HTTP OPTIONS
requests for CORS.

DAIA server and client MUST use HTTPS when sending and receiving access tokens.

Distribution of access tokens is out of the scope of this specification.

When also using PAIA it is RECOMMENDED to issue access tokens via PAIA auth and
add a scope named `read_availability` for authentificated access to a DAIA
server.

<div class="example">
The following requests both include the same access token for authentification.

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

* Galiegue, F. and Zyp, K. 2013: "JSON Schema v4".
  <http://json-schema.org/latest/json-schema-core.html>.

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
  a modification a DAIA servers
* The patch version (third number) is increased for backwards compatible
  fixes or extensions, such as the introduction of new optional fields
* The optional suffix indicates informal changes in documentation

### Releases {.unnumbered}

Releases with functional changes are tagged with a version number and
included at <https://github.com/gbv/daia/releases> with release notes.

#### 0.9.6 (2015-12-02) {.unnumbered}

* Require escaping of vertical bar in query id
* Better explain openaccess service and add suggested license limitations

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
* Added authentification
* Added patron-specific availability
* Added CORS and HTTP OPTIONS
* Added field about to document and item
* Entities must at least have one field (id, content, and/or href)

#### 0.8 (2015) {.unnumbered}

* Added DAIA Simple

#### 0.5 (2009) {.unnumbered}

* First specification

### Full changelog {.unnumbered}

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
service    string   most relevant [service](#services) (one of `openaccess`, `loan`, `presentation`, `none`)
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

## Service limitations
[service limitations]: #service-limitations

DAIA does not specify a mandatory set of [service limitations](#services) to be
understood by DAIA servers and DAIA clients. The following service limitation
URIs are RECOMMENDED to be used if applicable:

### Creative Commons Licenses

A limitation with `id` starting with `http://creativecommons.org/license/`
SHOULD be used to refer to a specific Creative Commons License for service type
`openaccess`. Note that limitations of this service type, in contrast to other
service types, do not refer to access but to usage rights.

<div class="example">
An Open Access journal article licensed under CC-BY 3.0 (US):

```json
{
  "about": "Editorial Introduction: The Code4Lib Journal Experiment, Rejection Rates, and Peer Review", 
  "available": [ { 
    "service": "openaccess",
    "href": "http://journal.code4lib.org/articles/3277",
    "limitation": {
      "id": "http://creativecommons.org/licenses/by/3.0/us/",
      "href": "https://creativecommons.org/licenses/by/3.0/us/",
      "content": "CC-BY 3.0 US"
    }
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
    "limitation": {
      "id": "http://creativecommons.org/licenses/publicdomain/",
      "href": "https://creativecommons.org/licenses/publicdomain/",
      "content": "Public Domain"
    }
  } ]
}
```
</div>

## JSON Schema

[JSON Schema]: #json-schema

The following JSON Schema [`daia.schema.json`](daia.schema.json) can be used
to validate [DAIA Response] format without [integrity rules].

`daia-schema/daia.schema.json`{.include .codeblock .json}
`daia.schema.json`{.include .codeblock .json}

# Acknowledgements

Thanks for contributions to DAIA specification from Uwe Reh, David Maus, Oliver
Goldschmidt, Jan Frederik Maas, Jürgen Hofmann, Anne Christensen, and André
Lahmann among others.

----

This version: <http://gbv.github.io/daia/{CURRENT_VERSION}.html> ({CURRENT_TIMESTAMP})\
Latest version: <http://gbv.github.io/daia/>

Created with [makespec](http://jakobib.github.io/makespec/)
