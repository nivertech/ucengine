DIRS          = rel/ucengine/data/files

all: compile

$(DIRS):
	mkdir -p $(DIRS)

###############################################################################
# Build
###############################################################################
compile:
	./rebar get-deps
	./rebar compile

rel: compile
	./rebar generate force=1

###############################################################################
# Usual targets
###############################################################################
dev: rel $(DIRS)

wwwroot: $(DIRS)
	-@rm rel/ucengine/wwwroot/ -fr
	-@cp -r wwwroot rel/ucengine/.

run: dev
	rel/ucengine/bin/ucengine console

start: dev
	rel/ucengine/bin/ucengine start

stop:
	rel/ucengine/bin/ucengine stop

restart: dev
	rel/ucengine/bin/ucengine restart

tests: dev
	rel/ucengine/bin/ucengine-admin tests
	./rebar skip_deps=true eunit

dialyze: compile
	./rebar skip_deps=true check-plt
	./rebar skip_deps=true dialyze

###############################################################################
# Benchmark
###############################################################################

bench:
	@mkdir -p benchmarks/ebin/
	@erlc -o benchmarks/ebin/ benchmarks/tsung_utils.erl
	@mkdir -p benchmarks/results
	@./utils/benchmark $(SCENARIO)
	@rm -rf benchmarks/ebin

###############################################################################
# Cleanup
###############################################################################
clean:
	-@rm -v erl_crash.dump -f
	./rebar clean

.PHONY: clean bench
