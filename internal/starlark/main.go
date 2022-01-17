package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path"

	"go.starlark.net/starlark"
	"go.starlark.net/starlarkjson"
)

var input = flag.String("input", "", "input Starlark file path")
var output = flag.String("output", "", "output JSON file path")
var expr = flag.String("expr", "encode_indent(main())", "Starlark expression to call to produce output")

func main() {
	flag.Parse()
	if *input == "" || *output == "" {
		flag.Usage()
		os.Exit(1)
	}

	// Add JSON module to globals
	starlark.Universe["json"] = starlarkjson.Module

	// Resolve input Starlark program
	thread := &starlark.Thread{Name: "main", Load: MakeLoad(path.Dir(*input))}
	globals, err := starlark.ExecFile(thread, *input, nil, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to exec input file: %v", err))
	}

	// Resolve lib Starlark program
	libGlobals, err := starlark.ExecFile(thread, "internal_lib.star", lib, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to execute internal lib file: %v", err))
	}
	for key, val := range libGlobals {
		globals[key] = val
	}

	// Run wrapper that calls main and encodes as JSON
	val, err := starlark.Eval(thread, "eval_wrapper.star", *expr, globals)
	if err != nil {
		panic(fmt.Sprintf("failed to eval wrapper: %v", err))
	}

	// Ensure we got a String
	jsonString, ok := val.(starlark.String)
	if !ok {
		panic(fmt.Sprintf("expected String output, but got %T", val))
	}

	// Write JSON to output file
	err = ioutil.WriteFile(*output, []byte(jsonString.GoString()), 0644)
	if err != nil {
		panic(fmt.Sprintf("error writing to output file %s: %v", *output, err))
	}
}

// Small helper functions to make execution easier
const lib = `
def encode_indent(x):
    return json.indent(json.encode(x), indent='  ')

# Create local variable definitions for .tf.json file
def wrap_locals(x):
    if type(x) != "dict":
        fail("expected dict, got", type(x))
    return { "locals": x }

# Create a .tf.json backend block
def wrap_backend(backend_type, config):
    if type(backend_type) != "string":
        fail("expected string for backend_type, got", type(backend_type))

    if type(config) != "dict":
        fail("expected dict for config, got", type(config))

    return {
        "terraform": {
            "backend": {
                backend_type: config
            }
        }
    }

# Create a .tf.json terraform_remote_state block
def wrap_backend_remote_state(backend_type, config, variable_name):
    if type(backend_type) != "string":
        fail("expected string for backend_type, got", type(backend_type))

    if type(config) != "dict":
        fail("expected dict for config, got", type(config))

    if type(variable_name) != "string":
        fail("expected string for variable_name, got", type(variable_name))

    return {
        "data": {
            "terraform_remote_state": {
                variable_name: {
                    "backend": backend_type,
                    "config": config,
                },
            }
        }
    }
`

// MakeLoad returns a simple sequential implementation of module loading
// suitable for use in the REPL.
// Each function returned by MakeLoad accesses a distinct private cache.
func MakeLoad(workingDir string) func(thread *starlark.Thread, module string) (starlark.StringDict, error) {
	type entry struct {
		globals starlark.StringDict
		err     error
	}

	var cache = make(map[string]*entry)

	return func(thread *starlark.Thread, module string) (starlark.StringDict, error) {
		e, ok := cache[module]
		if e == nil {
			if ok {
				// request for package whose loading is in progress
				return nil, fmt.Errorf("cycle in load graph")
			}

			// Add a placeholder to indicate "load in progress".
			cache[module] = nil

			// Load it.
			thread := &starlark.Thread{Name: "exec " + module, Load: thread.Load}
			globals, err := starlark.ExecFile(thread, path.Join(workingDir, module), nil, nil)
			e = &entry{globals, err}

			// Update the cache.
			cache[module] = e
		}
		return e.globals, e.err
	}
}
