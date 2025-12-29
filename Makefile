build: force
	docker build . \
		--no-cache \
		--build-arg CURSOR_URL=$(CURSOR_URL) \
		--build-arg USERID=$(shell id -u) \
		--build-arg USERNAME=$(shell id -u -n) \
		-t ai-ide

run: force
	./cursor.ide bash

force:
