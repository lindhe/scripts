.PHONY: test install

test:
	shellcheck ./src/backup.sh
	shellcheck ./src/check_alive.sh

install: test
	mkdir -p /etc/backup
	cp -i ./src/backup.sh /etc/backup
	cp -i ./config/exclude.txt /etc/backup

