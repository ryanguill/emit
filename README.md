emit
====

#CFML Event Emitter

The primary goal of this project is to be similar to the event emitter in node.js, although this project might deviate
in some ways from its api.

Note: this project is just getting started.  Documentation and tests will be sparse for the time being.  Pull requests 
for code, documentation or tests welcome!

##Quick Start Guide:

Extend emit.cfc with any cfc you want.  There is no constructor so no need to call an init method.  

To emit an event from inside of your cfc

    emit(eventname, [data]);
    
or call emit from outside if you need to:

	instance.emit(eventname, [data]);
    
To listen for an event from inside of your cfc:

	addEventListener(eventName, listener);
	
or more likely, from the outside:

	instance.addEventListener(eventName, listener);

	
Usually the listener will be an anonymous function (which might or might not be a closure):

	instance.addEventListener("eventName", function(data) {
		...
	});
	
Note: Event names are case sensitive by default.  You can call setCaseSensitiveEventNames(false) to change this.

Most functions return an instance of the object so that they can be chained.

##API:

	addEventListener (required string event, required any listener, boolean async = false, boolean once = false)
	on (required string event, required any listener, boolean async = false)
	once (required string event, required any listener, boolean async = false)
	removeListener (required string event, required any listener)
	removeAllListeners (required string event)
	listeners (required string event)
	emit(required string event)
	dispatch (required string event)
	dispatchError ()
	
Other Methods:

	getMaxListeners ()
	setMaxListeners (required numeric n)
	isCaseSensitiveEventName ()
	setCaseSensitiveEventName (required boolean value)
	