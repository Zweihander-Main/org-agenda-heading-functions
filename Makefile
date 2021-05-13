SOURCE := org-agenda-heading-functions.el
TEST   := ./test/org-agenda-heading-functions-test.el

.PHONY: test

test:
	cask exec buttercup -L .

testWatch:
	while true; do \
		make test; \
		inotifywait -qre close_write $(SOURCE) $(TEST); \
	done

lint:
	cask exec elsa $(SOURCE)