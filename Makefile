.PHONY: run check docs-check docs-impact clean

run:
	ruby core.rb

check:
	./scripts/check.sh

docs-check:
	python3 scripts/check_docs.py

docs-impact:
	python3 scripts/check_docs.py --changed

clean:
	rm -rf build
