var assert    = require('assert');
var glob      = require('glob');
var jsonfile  = require('jsonfile');
var fs        = require('fs');
var validator = require('is-my-json-valid');
var jsonld    = require('jsonld');
var N3        = require('n3');
var N3Util    = N3.Util;

var schema = jsonfile.readFileSync('daia.schema.json');
var context = jsonfile.readFileSync('daia.context.json');

var valid  = validator(schema);

function toRDF(doc) {
  console.log(JSON.stringify(doc,null,2).replace(/^/gm,'# '));

  doc['@context'] = context;

  var turtleWriter = N3.Writer({ prefixes: {
	rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
    data: 'http://purl.org/ontology/daia/',
    xsd: 'http://www.w3.org/2001/XMLSchema#',
	dso: 'http://purl.org/ontology/dso#',
	holding: 'http://purl.org/ontology/holding#',
	service: 'http://purl.org/ontology/service#',
	dc: 'http://purl.org/dc/elements/1.1/'
} });

  // hook Turtle writer on top of jsonld library    
  jsonld.promises.toRDF(doc, {format: 'application/nquads'}).then(
	function(nquads) {
	  N3.Parser().parse(nquads, function(error, triple, prefixes) {
        if (triple) {
  		  turtleWriter.addTriple(triple);
		} else {
	      turtleWriter.end(function (error, result) {
		    turtle = result.replace(/^@.+(\r?\n|$)/gm,'');
            console.log(turtle.replace(/^/gm,'# '));
		  });
		}
	  });
	}, function(err) {
	  assert(false);
	});
}

describe('DAIA JSON Schema', function() {
  glob.sync('../examples/response-*.json', {}).forEach(function(file) {
    it('validates ' + file, function() {
      var doc = jsonfile.readFileSync(file);
	  var ok = valid(doc);
      if (ok) toRDF(doc);
      assert(ok);
    });
  });
  // TODO: validate service and entity
  fs.readFileSync('../examples/invalid.ldjson').toString().split('\n').forEach(
    function(line) {
      if (line != "") {
        var data = JSON.parse(line);
        it('detects violation',function() {
          assert(!valid(data));
        });
      }
    }
  );
});
