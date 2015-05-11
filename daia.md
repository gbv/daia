# Introduction

...

## Status of this document

All sources and updates can be found in a public git repository at
<http://github.com/gbv/daia>. See the [list of releases](#releases) at
<https://github.com/gbv/daia/releases> for functional changes.

The master file [daia.md](https://github.com/gbv/daia/blob/master/daia.md) is
written in [Pandoc’s Markdown].  HTML version of the specification is generated
from the master file with [makespec](https://github.com/jakobib/makespec). The
specification can be distributed freely under the terms of CC-BY-SA.

[Pandoc’s Markdown]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html

## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

# Data format

Document Availability Information in DAIA is expressed in JSON. A DAIA server
MUST return a [DAIA response] or an [error response].

## Data types

The following data types are used to defined [DAIA response] format and [DAIA Simple] format.

### Simple data types {.unnumbered}

string
  : A Unicode string. A DAIA client MUST treat fields with empty string value 
    equal to non-existing fields.
URI
  : A syntactically correct URI.
URL
  : A syntactically correct HTTP or HTTPS URL.
nonNegativeInteger
  : A non-negative integer.
boolean
  : A Boolean value (`true` or `false`).
datetime
  : An instant of time specified in the form `YYYY-MM-DDThh:mm:ss(.ss)?(Z|[+-]hh:mm)?`
    as defined with [XML Schema datatype xsd:dateTime](http://www.w3.org/TR/xmlschema-2/#dateTime).
    A timezone indicator SHOULD be included.
duration
  : A duration as defined with 
    [XML Schema datatype xsd:duration](http://www.w3.org/TR/xmlschema-2/#duration)
    the string `unknown` to indicate a duration of unknown length.
entity
  : A JSON object with the following optional fields:

    name    type    description
    ------- ------- ------------
    id      URI     ...
    href    URL     ...
    content string  ...
    ------- ------- ------------

### document {.unnumbered}

A **document** is a JSON object with one mandatory and three optional fields:

name      type                    description
--------- ------------- --------- --------------
id        URI           mandatory ...
requested string        optional  ...
href      URL           optional  ...
item      array of item optional  ...
--------- ------------- --------- --------------

...

One of `document.id` and `document.requested` MUST match to the queried identifier.

...

#### Example {.unnumbered}

```{.json}
{
  "href": "https://kataloge.uni-hamburg.de/DB=1/PPNSET?PPN=57793371X",
  "id": "http://uri.gbv.de/document/gvk:ppn:57793371X",
  "requested": "gvk:ppn:57793371X",
  "item": [ {

  } ]
}
```

### item {.unnumbered}

An **item** is a JSON object with the following optional fields:

name        type                    description
----------- ----------------------- ------------
id          URI                     ...
href        URL                     ...
part        string                  ...
label       string                  ...
department  entity                  ...
storage     entity                  ...
available   array of availability   ...
unavailable array of unavailability ...
----------- ----------------------- ------------

...

Partial items refer to items which contain less (narrower) or more (broader)
than the whole document.

...

#### Example {.unnumbered}

```{.json}
{
  "id": "id:123",
  "message": [ { "lang": "en", "content": "foo" } ],
  "department": { "id": "id:abc" },
  "label": "bar",
  "available":   [ {"service" : "presentation"}, 
                   {"service" : "loan"}, 
                   {"service" : "interloan"} ],
  "unavailable": [ {"service" : "openaccess"} ]
}
```

### availability {.unnumbered}

A **availability** is a JSON object with the following optional fields:

name        type                 description
----------- -------------------- ------------
service     string or URI        ...
href        URL
delay       duration             estimated delay (if given).
limitation  entity               ...
----------- -------------------- ------------

If `delay` is missing, then there is probably no significant delay.  If `delay`
is `unknown`, then there is probably a delay but its duration is unknown.

...

#### Example {.unnumbered}

```{.json}
{ 
  "service": "loan",
  "delay": "PT2H" 
}
```

### unavailability {.unnumbered}

An **unavailable** is a JSON object with the following optional fields:

name        type            description
----------- --------------- ------------
service     string or URI   ...
href        URL             ...
expected    ...             ...
queue       ...             ...
limitation  array of entity ...
----------- --------------- ------------

## DAIA response format

[DAIA response format]: #daia-response-format
[DAIA response]: #daia-response-format

A DAIA response is a JSON object with three optional fields:

 name        type              description
------------ ----------------- -----------------------------------------------------------------------
 institution entity            institution that grants or knows about services and their availability 
 document    array of document ...
 timestamp   datetime          ...
------------ ----------------- -----------------------------------------------------------------------


**TODO:** 

* paginated results for query ids with multiple ids

* A DAIA client MUST treat fields with empty JSON arrays (e.g. `document`,
  `item`) equal to non-existing fields. 

* A DAIA server MAY include additional fields which SHOULD be ignored by DAIA clients.

* ...


## DAIA Simple

**DAIA Simple** is a simplified version of [DAIA response format] that only
covers a typical use case of availability information.  A DAIA simple object is
a plain JSON object with the following fields:

service
  : most relevant service (`openaccess`, `loan`, `presentation`, `none`)
available
  : boolean value (`true` or `false`)
delay
  : optional field only allowed if available=`true`. Allowed
    values must conform to `xsd:duration` or be the string `unknown`.
expected
  : Only if available=`false`. Allowed values must
    conform to `xsd:date` or `xsd:dateTime` or be the string `unknown`.
queue
  : length of waiting queue (only if available=`false`)
href
  : optional URL to perform or request a service.
limitation
  : optional string or boolean value describing an additional limitation.

### Examples {.unnumbered}

~~~ {.json}
{ "service": "loan", "available": true }
{ "service": "loan", "available": false, "expected": "2014-12-07" }
{ "service": "presentation", "available": true }
{ "service": "openaccess", "available": true,
  "href": "http://dx.doi.org/10.1901%2Fjaba.1974.7-497a" }
~~~
 

# Request and response

[query id]: #request-and-response
[query parameter]: #request-and-response

A DAIA server is queried via HTTP or HTTPS GET request and the following query parameters:

id
  : query id with identifiers of documents or items
format
  : set to `json` (mandatory)
callback
  : a JavaScript callback method name to return JSONP instead of JSON. The callback MUST 
    only contain alphanumeric characters and underscores
patron
  : a patron identifier for [patron-specific availability]
access_token
  : an [access token] for authentification
suppress_response_codes
  : if this parameter is present, all responses MUST be returned with a 200 OK status code,
    even [request errors]. Support of this parameter is OPTIONAL.

The URL to query a DAIA server when stripped from these six query parameters is
called its **base URL**. It is RECOMMENDED to use a HTTPS base URL. A DAIA
client MUST NOT send an access token via HTTP.

A DAIA server SHOULD also support HTTP HEAD and HTTP OPTIONS requests.

A missing parameter `format` or another value but `json` or `simple` SHOULD result in a
HTTP [error response] with status 422 (invalid request).

**TODO**

* query ID for multiple documents (HTTP 422: query ID too long)
* `Link` to to refer to a list of next [query id] if the query id was only processed partially


### Request headers {.unnumbered}

A DAIA client SHOULD sent the following HTTP request headers:

User-Agent
  : with an appropriate client name and version number
Accept
  : with the value `application/json`

A DAIA client MAY sent the following HTTP request headers:

Accept-Language
  : to indicate preferred languages of textual response fields (`content`)
Authorization
  : to provide an access token for [patron-specific availability] as OAuth 2
    Bearer token.

For OPTIONS preflight requests of Cross-Origin Resource Sharing (CORS) a DAIA
client MUST include the following HTTP request headers:

Origin
  : where the cross-origin request originates from
Access-Control-Request-Method
  : the HTTP verb `GET`
Access-Control-Request-Headers
  : the value `Authorization` if access tokens are sent as HTTP headers

Note that DAIA clients are not required to respect CORS rules. CORS preflight
requests in browsers can be avoided by omitting the request headers `Accept`
and `Authorization`.

### Response headers {.unnumbered}

A DAIA server SHOULD sent the following HTTP response headers with every [DAIA response]:

Content-Language
  : to indicate the language of textual response fields (`content`)
Content-Type
  : the value `application/json` or `application/json; charset=utf-8` for JSON response;
    the value `application/javascript` or `application/javascript; charset=utf-8` for JSONP response
X-DAIA-Version
  : the version of DAIA specification which the server was checked against
Link
  : to refer to the next [query id] for paginated results

### Response errors {.unnumbered}

[error response]: #response-errors

A DAIA server SHOULD use HTTP status codes to indicate server errors and client
request errors. An error response SHOULD include a JSON object with the
following fields:

error
  : alphanumeric error code
code
  : HTTP status code
error_description
  : human-readable error description (optional)
error_uri
  : human-readable web page about the error (optional)

The following error responses are expected:

 error               code  description
-------------------- ---- -----------------------------------------------------------------------
 invalid_request      400  Malformed request, for instance malformed HTTP request headers
 invalid_grant        401  The [access token] was missing, invalid, or expired
 insufficient_scope   403  The access token was accepted but it lacks permission for the request
 invalid_request      405  Unexpected HTTP verb
 invalid_request      422  Missing or invalid request parameters
 internal_error       500  An unexpected error occurred, such as a serious bug
 not_implemented      501  Access token was sent but no support of [patron-specific availability]
 bad_gateway          502  The request couldn't be serviced because of a backend failure
 service_unavailable  503  The request couldn't be serviced because of a temporary failure
 gateway_timeout      504  The request couldn't be serviced because of a backend failure
-------------------- ----- ------------------------------------------------------------------------

A DAIA server SHOULD never return a HTTP 404 error if queried at its [base
URL]. In particular a DAIA server MUST NOT respond with a HTTP 404 status code
for missing or unknown [query id].

For backwards compatibility with DAIA 0.5, a DAIA server MAY respond with a
HTTP 200 status code (instead of 422) and an arbitrary document if query
parameter `format` has not been set to `json`. The document returned in this
case MUST NOT be JSON. A DAIA client MAY translate the document to a valid
[DAIA response], for instance from XML.


# Patron-specific availability

[patron-specific availability]: #patron-specific-availability
[access token]: #patron-specific-availability

A DAIA server MAY support patron-specific availability with the [query
parameter] `patron` and an optional access token. A DAIA server that does not
support patron-specific availability SHOULD respond with [error response]
status 501 (not supported) when it receives a request with query parameter
`patron`.  A DAIA server that supports patron-specific availability, MUST also
support HTTP OPTIONS requests for CORS.

DAIA server and client MUST use HTTPS when sending and receiving access tokens.

...

# References

## Normative References

* Berners-Lee, T., Fielding R., Masinter L. 1998. “Uniform Resource Identifiers (URI): Generic Syntax”.
  <http://tools.ietf.org/html/rfc2396>

* Biron, P. V., Malhotra, A. 2004. “XML Schema Part 2: Datatypes Second Edition”.
  <http://www.w3.org/TR/xmlschema-2/>

* Bradner, S. 1997. “RFC 2119: Key words for use in RFCs to Indicate Requirement Levels”.
  <http://tools.ietf.org/html/rfc2119>

* Crockford, D. 2006. “RFC 6427: The application/json Media Type for JavaScript Object Notation (JSON)”.
  <http://tools.ietf.org/html/rfc4627>

* Fielding, R. 1999. “RFC 2616: Hypertext Transfer Protocol”.
  <http://tools.ietf.org/html/rfc2616>

* Jones, M. and Hardt, D. 2012. “RFC 6750: The OAuth 2.0 Authorization Framework: Bearer Token Usage”.
  <http://tools.ietf.org/html/rfc6750>.

* van Kesteren, A. 2014. “Cross-Origin Resource Sharing”
  <http://www.w3.org/TR/cors/>

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

#### 0.9.? (2015-05-??) {.unnumbered}

* Removed DAIA/XML and DAIA/RDF
* Added DAIA Simple
* Dropped fields `message`, `version`, `schema`
* Made `format` query parameter mandatory
* Added support of authentificated DAIA
* Added CORS (HTTP OPTIONS request)
* Added paginated results to better support querying multiple IDs
* New field `requested` to map query id to documents

#### 0.5 (2009) {.unnumbered}

* First specification

### Full changelog {.unnumbered}

{GIT_CHANGES}

## Acknowledgements

Thanks for contributions to DAIA specification from Uwe Reh, David Maus, Oliver
Goldschmidt, Jan Frederik Maas, Jürgen Hofmann, Anne Christensen, and André
Lahmann among others.

