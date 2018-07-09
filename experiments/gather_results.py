import json
from glob import iglob
from itertools import chain


def read_json(filename):
    with open(filename) as f:
        return json.load(f)


def main():
    files = iglob('**/results.json', recursive=True)
    json_data = (read_json(i) for i in files)
    print(list(chain.from_iterable(json_data)))

if __name__=="__main__":
    main()