
all: init build

init:
	pipenv install --dev

build:
	pipenv run pyinstaller --onefile --distpath=. ./update_dns_record.py

test:
	pipenv run mypy ./update_dns_record.py
	pipenv run pylint ./update_dns_record.py

clean:
	rm -r build update_dns_record.spec

install:
	install ./update_dns_record /usr/local/bin/
