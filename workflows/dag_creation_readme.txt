An example DAG worflow (from the RPA example) is below:

{"dag": {
	"/sensor": "/service1",
	"/service1": ["/service2", "/service3"],
	"/service2": "/service4",
	"/service3": "/service4",
	"/service4": "/consumer"
	}
}

Each key is the service name that feeds the services in its values.

We can split the JSON structure to only represent a single DAG edge (a single key-value pair) per line:

{"dag": {
	"/sensor": "/service1",
	"/service1": ["/service2"],
	"/service1": ["/service3"],
	"/service2": "/service4",
	"/service3": "/service4",
	"/service4": "/consumer"
	}
}

which represents exactly the same workflow as before.


For services that take in more than one input, we need to keep track of which input is which. For this purpose, the ORDER in which they appear in the JSON structure IS IMPORTANT! Changing the order in which they appear will effectively change their input index number.


Update: JSON is organized alphabetically, so the order is lost!

We modified the workflow to include the input order information:

{	"dag": {
		"/sensor": {
			"/service1": 0
		},
		"/service1": {
			"/service2": 0,
			"/service3": 0
		},
		"/service2": {
			"/service4": 0
		},
		"/service3": {
			"/service4": 1
		},
		"/service4": {
			"/consumer": 0
		}
	}
}

In the example above, service 2 feeds into service 4's input #0, while service 3 feeds into service 4's input #1.
