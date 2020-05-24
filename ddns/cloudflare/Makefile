
all: init build

init:
	pipenv install --dev

build:
	pipenv run pyinstaller --onefile --distpath=./bin ./update_dns_record.py

test:
	pipenv run mypy ./update_dns_record.py
	pipenv run pylint ./update_dns_record.py
	./tests.sh

package:
	pipenv run pipenv_to_requirements
	snapcraft

clean:
	rm -rf build update_dns_record.spec lindhe-cloudflare-ddns_*_amd64.snap requirements*.txt
	snapcraft clean

install:
	install ./update_dns_record /usr/local/bin/
