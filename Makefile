# Munch or Dump — mobile app dev commands.
# Environment is selected by a --dart-define-from-file config (see config/*.json).
# Native dev/prod flavors (separate installable apps) land in Phase 1 with signing.

.PHONY: setup gen watch run run-prod test analyze format doctor clean

setup:        ## Install dependencies
	flutter pub get

gen:          ## Run codegen once (json_serializable, etc.)
	dart run build_runner build

watch:        ## Run codegen in watch mode
	dart run build_runner watch

run:          ## Run the app against the dev config
	flutter run --dart-define-from-file=config/dev.json

run-prod:     ## Run the app against the prod config
	flutter run --dart-define-from-file=config/prod.json

test:         ## Run the test suite
	flutter test

analyze:      ## Static analysis
	flutter analyze

format:       ## Format all Dart sources
	dart format .

doctor:       ## Flutter environment health check
	flutter doctor

clean:        ## Remove build artifacts
	flutter clean
