default: install

h help:
	@egrep '^\S|^$$' Makefile

config: install

debug:
	npm run debug

install:
	bundle config set --local path vendor/bundle
	bundle install
	npm install

s serve:
	bundle exec jekyll serve --trace --livereload	

build:
	npm run build	