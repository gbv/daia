var assert    = require('assert');
var glob      = require('glob');
var jsonfile  = require('jsonfile');
var fs        = require('fs');
var validator = require('is-my-json-valid');

var schema = jsonfile.readFileSync('../daia.schema.json');
var valid  = validator(schema);

describe('DAIA JSON Schema', function() {
  glob.sync('../examples/response-*.json', {}).forEach(function(file) {
    it('validates ' + file, function() {
      var data = jsonfile.readFileSync(file);
      assert(valid(data));
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
