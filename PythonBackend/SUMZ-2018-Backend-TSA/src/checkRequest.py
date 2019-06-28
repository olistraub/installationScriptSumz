from jsonschema import validate
from flask import abort
from os.path import join, dirname
import jsonref

#created by Fabian Wallisch WWI16

def check(json, schema):
    return validate(instance=json, schema=schema)
        
def loadSchema(filename):
    relative_path = join('schemas', filename)
    absolute_path = join(dirname(__file__), relative_path)

    base_path = dirname(absolute_path)
    base_uri = 'file://{}/'.format(base_path)

    #opening the schema file
    with open(absolute_path) as schema_file:
        return jsonref.loads(schema_file.read(), base_uri=base_uri, jsonschema=True)
    