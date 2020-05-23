
all: init build

init:
	pipenv install --dev

build:
	pipenv run pyinstaller ./update_dns_record.py

test:
	pipenv run mypy ./update_dns_record.py
	pipenv run pylint ./update_dns_record.py

clean:
	rm -r dist build update_dns_record.spec
