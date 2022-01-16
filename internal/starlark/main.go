package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"

	"go.starlark.net/starlark"
	"go.starlark.net/starlarkjson"
)

var input = flag.String("input", "", "input Starlark file path")
var output = flag.String("output", "", "output JSON file path")

func main() {
	flag.Parse()
	if *input == "" || *output == "" {
		flag.Usage()
		os.Exit(1)
	}

	// Execute input Starlark program
	thread := &starlark.Thread{Name: "main", Load: MakeLoad()}
	globals, err := starlark.ExecFile(thread, *input, nil, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to load input file: %v", err))
	}

	// Retrieve main function
	main := globals["main"]

	// Call main function to get return value
	val, err := starlark.Call(thread, main, nil, nil)
	if err != nil {
		panic(fmt.Sprintf("failed to run: %v", err))
	}

	// Encode return value as JSON inside Starlark
	encode, ok := starlarkjson.Module.Members["encode"]
	if !ok {
		panic(fmt.Sprintf("Couldn't find encode in json module: %v", starlarkjson.Module))
	}

	valJSON, err := starlark.Call(thread, encode, starlark.Tuple([]starlark.Value{val}), []starlark.Tuple{})
	if err != nil {
		panic(fmt.Sprintf("failed to produce JSON from main() result: %v", err))
	}

	// Indent JSON inside Starlark
	indent, ok := starlarkjson.Module.Members["indent"]
	if !ok {
		panic(fmt.Sprintf("Couldn't find indent in json module: %v", starlarkjson.Module))
	}

	indentedJSON, err := starlark.Call(thread, indent, starlark.Tuple([]starlark.Value{valJSON}), []starlark.Tuple{})
	if err != nil {
		panic(fmt.Sprintf("failed to produce JSON from main() result: %v", err))
	}

	// Ensure we got a String
	jsonString, ok := indentedJSON.(starlark.String)
	if !ok {
		if err != nil {
			panic(fmt.Sprintf("output of encode() was not String, but %T", valJSON))
		}

	}

	// Write JSON to output file
	err = ioutil.WriteFile(*output, []byte(jsonString.GoString()), 0644)
	if err != nil {
		panic(fmt.Sprintf("error writing to output file %s: %v", *output, err))
	}
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

			// Load it.
			thread := &starlark.Thread{Name: "exec " + module, Load: thread.Load}
			globals, err := starlark.ExecFile(thread, module, nil, nil)
			e = &entry{globals, err}

			// Update the cache.
			cache[module] = e
		}
		return e.globals, e.err
	}
}
