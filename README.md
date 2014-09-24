emit
====

#CFML Event Emitter

The primary goal of this project is to be similar to the event emitter in node.js, although this project might deviate
in some ways from its api.  It also seeks to provide an easy way to create async code in CFML.  Any event listener can be created as async.

> Note! this project is just getting started.  It has been mostly tested, but I am not claiming 100% coverage yet.  The API is not finalized and very well could change.  Consider it beta quality at this point.  Don't use it in production without testing it for yourself.  Pull requests or issues for code, documentation or tests welcome!

I aim to support Railo 4+ first, and ACF 10+ secondarily.  You could probably back-port this project to tag based to as far as CF 8 - this is left as an exercise for the cursed.  I am not interested in tag based pull requests for this project.

##Quick Start Guide:

Extend emit.cfc with any cfc you want.  There is no constructor so no need to call an init method.  Or, if you just need an application wide event manager, just instantiate emit.cfc directly.

To emit an event from inside of your cfc

    emit(eventname, [data]);
    
or call emit from outside if you need to:

    instance.emit(eventname, [data]);
    
To listen for an event from inside of your cfc:

    addEventListener(eventName, listener);
	
or more likely, from the outside:

    instance.addEventListener(eventName, listener);

Usually the listener will be an anonymous function (which might or might not be a closure):

'''
instance.addEventListener("eventName", function(data) {
    ...
});
'''

Note: Event names are case sensitive by default.  You can call setCaseSensitiveEventNames(false) to change this.

Most functions return an instance of the object so that they can be chained.

##API:

__addEventListener (required string event, required any listener, boolean async = false, boolean once = false)__

Creates an event listener for a particular event emitted by the instance that you are calling addEventListener on.  Event is case sensitive by default.  Listener can be any custom function.  Async defaults to false.  If you use async true, the listener will be executed in a separate thread.  Keep the following in mind:

- You will not be guaranteed that it will run at any particular time or order.
- You will not be able to send data into the output buffer.  This makes debugging difficult - use logging or write out files.
- You will have access to the data that you close over inside of your listener.  Make sure you have everything you need.

Once defaults to false - setting once to true will automatically remove the event listener the first time it is called.  Useful for fire once async handling.

If you try to add an event listener which exceeds the limit, an exception of type Emit.Emit.maxListenersExceeded will be thrown. See setMaxListeners().

	
__on (required string event, required any listener, boolean async = false)__

Alias for addEventListener().

__once (required string event, required any listener, boolean async = false)__

Alias for addEventListner() with once=true.

__removeListener (required string event, required any listener)__

To remove a listener, you must pass in the exact listener you used to add the event listener initially.  Which means if you intend to remove a listener you need to create the listener in a separate variable and use it to both add and remove.

__removeAllListeners (required string event)__

Removes all listeners for a given event.

__listeners (required string event)__

Gets an array of all of the listeners.  Each item in the array is a structure with the keys: listner (function), async (boolean), and once (boolean);

__emit(required string event, [other arguments])__

Fires an event of the given type.  Remember that events are case sensitive by default.  Event name is the only required argument, you can pass whatever other data you want into emit (or dispatch) and it will be passed along to the listner.

__dispatch (required string event, [other arguments])__

Alias for emit().

__async (required any f)__

Convenience method.  Give it a function, it will run it in a separate thread.

__pipeline(event)__

Not Yet Documented

__dispatchError ()__

Convenience function for dispatching an event on "error".  By default, any exceptions in the calling of the listener will redispatch to "error", with an added argument of *exception*.  If no listeners exist for the "error" event, the exception is thrown.  


Other Methods:

__getMaxListeners ()__

By default, there is a limit of 10 listeners on a given event.  This is to help identify memory leaks and to listeners that are not being removed properly.  This will not be appropriate for all applications.  use setMaxListeners() to set to an appropriate level for your needs.  If you try to add an event listener which exceeds the limit, an exception of type Emit.Emit.maxListenersExceeded will be thrown.


__setMaxListeners (required numeric n)__

Set the maximum listeners per event. You must do this per instance of emit (or subclass). See getMaxListeners().

__isCaseSensitiveEventName ()__

Be default, emit treats event names as case sensitive.  This method returns true by default.  use setCaseSensitiveEventName() to override.  You must do this per instance of emit (or subclass).

__setCaseSensitiveEventName (required boolean value)__

see isCaseSensitiveEventName().

##Tests

Download and provide a mapping to testbox in /tests/Application.cfc, then run tests/index.cfm?opt_run=true


##License

_Apache 2.0_

Copyright 2014 Ryan Guill

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

