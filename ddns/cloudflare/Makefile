BASENAME='update_dns_record'
BUILD_DIR='./build'
BIN_DIR='./bin'

all: init build

init:
	pipenv install --dev

test:
	pipenv run mypy ./update_dns_record.py
	pipenv run pylint ./update_dns_record.py

build:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)
	pipenv run cython -3 --embed -o ./$(BUILD_DIR)/$(BASENAME).c ./$(BASENAME).py
	gcc -Os -I /usr/include/python3.7m -o $(BIN_DIR)/$(BASENAME) ./$(BUILD_DIR)/$(BASENAME).c -lpython3.7m -lpthread -lm -lutil

clean:
	rm -r $(BUILD_DIR)

install:
	install $(BIN_DIR)/update_dns_record /usr/local/bin/
