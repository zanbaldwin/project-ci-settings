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
	@echo "  deploy             Deploy project according to Ansible hosts and vars."
	@echo ""

### SETUP ###

composer: composer.json
	composer install

database: app/console
	app/console doctrine:database:create --if-not-exists
	app/console doctrine:schema:update --force

fixtures: database
	app/console doctrine:fixtures:load -n

node_modules:
ifneq ($(wildcard package.json),)
	npm install
endif

assets: app/console
	app/console assets:install
	app/console assetic:dump

setup: composer database
	# Clear the cache for production and testing, regardless of what environment
	# is being used. If we are on "dev" then the cache gets cleared automatically.
	app/console cache:clear -e prod
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

### DEPLOYMENT ###

deploy: provisions/symfony-playbook.yml
	sudo apt-get update && sudo apt-get install -y ansible
	ansible-playbook ./provisions/symfony-playbook.yml
