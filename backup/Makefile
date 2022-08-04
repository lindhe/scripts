.PHONY: test install

test:
	shellcheck ./backup.sh
	shellcheck ./check_alive.sh

install: test
	mkdir -p /etc/backup
	cp -i ./backup.sh /etc/backup
	cp -i ./exclude.txt /etc/backup

