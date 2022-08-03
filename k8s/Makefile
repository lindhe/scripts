.PHONY: test install

test:
	shellcheck ./get-kubeconfig.sh

install: test
	install ./get-kubeconfig.sh /usr/local/bin/get-kubeconfig

