.PHONY: test

test:
	echo "Testing"
	nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = './scripts/tests/minimal.vim'}"
