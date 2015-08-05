# A Note About Environment.
# This Makefile is for testing environments ONLY. It's intended for quickly provisioning up the project so that it can
# be tested easily of either a development machine or CI build. It is not in any way intended for deployment or
# production. YOU HAVE BEEN WARNED.

usage:
	@echo "Usage: make <command>"
	@echo ""
	@echo "  setup              Setup your environment for building, testing and running."
	@echo "  | composer         Install project dependencies and parameters."
	@echo "  | node_modules     Install NodeJS dependencies if the package.json exists."
	@echo "  | database         Ensure database is created with up-to-date schema."
	@echo "  | fixtures         Load initial application data into the database."
	@echo "  | assets           Install and compile/build assets."
	@echo ""
	@echo "  test               Run all tests."
	@echo "  | unit_tests       Run unit tests via PHPUnit."
	@echo "  | functional_tests Run functional tests via Behat."
	@echo "  | coding_standards Check source code adheres to coding standards."
	@echo "  | security_check   Check dependencies have no known security vulnerabilities."
	@echo ""

### SETUP ###

composer: composer.json
	# Although specifying the "no interaction" flag means that we might get some cases where the incorrect parameters
	# are used, it's better than not having any parameter.yml file at all in our CI build.
	composer install -n

database: app/console
	app/console doctrine:database:create --if-not-exists -e test
	app/console doctrine:schema:update --force -e test

fixtures: database
	app/console doctrine:fixtures:load -n -e test

node_modules:
ifneq ($(wildcard package.json),)
	npm install
endif

assets: app/console
	app/console assets:install -e test
	app/console assetic:dump -e test

setup: composer database
	app/console cache:clear -e test

### TESTS ###

unit_tests: setup phpunit.xml
	./bin/phpunit --configuration phpunit.xml
	./bin/humbug

functional_tests: setup node_modules assets fixtures behat.yml
	./bin/behat

coding_standards: composer ruleset.xml phpmd.xml
	./bin/phpcs ./src --standard=ruleset.xml
	./bin/phpmd ./src text ./phpmd.xml

security_check: composer composer.lock
	./bin/security-checker security:check ./composer.lock

test: setup unit_tests functional_tests coding_standards security_check
