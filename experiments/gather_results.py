import json
import logging
from glob import iglob
from itertools import chain

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def read_json(filename):
    logger.info('Reading {}...'.format(filename))
    with open(filename) as f:
        return json.load(f)

def write_json_to_file(json_data, filename):
    with open(filename, 'w') as outfile:
        json.dump(json_data, outfile)

def main(filename='all_results.json'):
    files = iglob('**/results.json', recursive=True)
    json_data = (read_json(i) for i in files)
    write_json_to_file(list(chain.from_iterable(json_data)), filename)
    logger.info('All results written to  {}'.format(filename))

if __name__=="__main__":
    main()