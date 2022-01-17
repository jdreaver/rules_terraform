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
var lib = flag.String("lib", "", "Starlark helper code to support running expr")

func main() {
	flag.Parse()
	if *input == "" || *output == "" {
		flag.Usage()
		os.Exit(1)
	}

	// Add JSON module to globals
	starlark.Universe["json"] = starlarkjson.Module

	// Resolve input Starlark program
	thread := makeThreadForFile(*input, MakeLoad())
	globals, err := starlark.ExecFile(thread, *input, nil, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to exec input file: %v", err))
	}

	// Resolve library code
	processLibrary(globals, thread, internalLib)
	processLibrary(globals, thread, *lib)

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

func processLibrary(globals starlark.StringDict, thread *starlark.Thread, libraryCode string) {
	libGlobals, err := starlark.ExecFile(thread, "internal_lib.star", libraryCode, globals)
	if err != nil {
		panic(fmt.Sprintf("failed to execute internal lib file: %v", err))
	}
	for key, val := range libGlobals {
		globals[key] = val
	}
}

// // Small helper functions to make execution easier
const internalLib = `
def encode_indent(x):
    return json.indent(json.encode(x), indent='  ')

def assert_type(x, expected_type):
    if type(x) != expected_type:
        fail("expected type", expected_type, "but got", type(x))
`

func makeThreadForFile(modulePath string, load func(thread *starlark.Thread, module string) (starlark.StringDict, error)) *starlark.Thread {
	thread := &starlark.Thread{Name: "exec " + modulePath, Load: load}
	// Current directory is stored in thread local variable
	// so we can resolve relative imports.
	thread.SetLocal("_source_dir", path.Dir(modulePath))
	return thread
}

// MakeLoad returns a simple sequential implementation of module loading
// suitable for use in the REPL.
// Each function returned by MakeLoad accesses a distinct private cache.
func MakeLoad() func(thread *starlark.Thread, module string) (starlark.StringDict, error) {
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

			// Current directory is stored in thread local variable
			// so we can resolve relative imports.
			sourceDirInterface := thread.Local("_source_dir")
			sourceDir, ok := sourceDirInterface.(string)
			if !ok {
				panic("internal error: couldn't find _source_dir thread local")
			}
			modulePath := path.Join(sourceDir, module)

			// Load it
			thread := makeThreadForFile(modulePath, thread.Load)
			globals, err := starlark.ExecFile(thread, modulePath, nil, nil)
			e = &entry{globals, err}

			// Update the cache.
			cache[module] = e
		}
		return e.globals, e.err
	}
}
