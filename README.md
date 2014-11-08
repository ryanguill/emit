emit
====

#CFML Event Emitter

The primary goal of this project is to be similar to the event emitter in node.js, although this project might deviate
in some ways from its api.  It also seeks to provide an easy way to create async code in CFML.  Any event listener can be created as async.

> Note! this project is in its early days still.  It has been mostly tested though and I do not expect any more API changes. Consider it a release canidate at this point. Pull requests or issues for code, documentation or tests welcome!

I aim to support Railo 4+ first, and ACF 10+ secondarily. ACF 10 is the first version with anonymous functions and closures that this project depends heavily on.  I am not interested in tag based pull requests for this project.

##Quick Start Guide:

emit.cfc in the lib folder is all you need.  Put it anywhere you want.  Extend emit.cfc with any cfc you want.  There is no constructor so no need to call an init method.  Or, if you just need an application wide event manager, just instantiate emit.cfc directly.

To emit an event from inside of your cfc

    emit(eventname, [optional struct of data]);
    
or call emit from outside if you need to:

    instance.emit(eventname, [optional struct of data]);
    
To listen for an event from inside of your cfc:

    addEventListener(eventName, listener);
	
or more likely, from the outside:

    instance.addEventListener(eventName, listener);

Usually the listener will be an anonymous function (which might or might not be a closure):

```
instance.addEventListener("eventName", function(data) {
    ...
});
```

Note: Event names are case sensitive by default.  You can call setCaseSensitiveEventNames(false) to change this.

Most functions return an instance of the object so that they can be chained.

##API:

__addEventListener (required string eventName, required any listener, boolean async = false, numeric timesToListen = -1)__

Creates an event listener for a particular event emitted by the instance that you are calling addEventListener on.  Event is case sensitive by default.  Listener can be any custom function.  Async defaults to false.  If you use async true, the listener will be executed in a separate thread.  Keep the following in mind:

- Event names must be a string.
- You will not be guaranteed that it will run at any particular time or order.
- You will not be able to send data into the output buffer.  This makes debugging difficult - use logging or write out files.
- You will have access to the data that you close over inside of your listener.  Make sure you have everything you need.
- You cannot use positional arguments in listners.  Only depend on named arguments.  You can depend on named arguments that are not defined in the method definition though.

timesToListen defaults to -1, which means it will listen until manually removed - setting it to 1 will automatically remove the event listener the first time it is called.  Useful for fire once async handling.

You can also provide the eventName argument as an array of event names to listen on multiple events with the same handler.

If you try to add an event listener which exceeds the limit, an exception of type Emit.maxListenersExceeded will be thrown. See setMaxListeners().  see also many().
	
__on (required string eventName, required any listener, boolean async = false)__

Alias for addEventListener().

__once (required string eventName, required any listener, boolean async = false)__

Alias for addEventListener() with timesToListen = 1.

__many (required string eventName, required any listener, required numeric timesToListen, boolean async = false)__

Alternative to addEventListener, useful for quickly setting a certain number of times to fire a particular listener.

__removeListener (required string eventName, required any listener)__

To remove a listener, you must pass in the exact listener you used to add the event listener initially.  Which means if you intend to remove a listener you need to create the listener in a separate variable and use it to both add and remove.

You can also provide the eventName argument as an array of event names to remove the same handler from multiple events.  This is only useful if you used the exact same handler for multiple events.

__off (required string eventName, required any listener)__

Alias for removeListener();

__removeAllListeners (required string eventName)__

Removes all listeners for a given event.
You can also provide the eventName argument as an array of event names to remove all listeners from multiple events.

__listeners (required string eventName)__

Gets an array of all of the listeners.  Each item in the array is a structure with the keys: listner (function), async (boolean), and once (boolean);

__emit (required string eventName, [optional arguments struct])__

Fires an event of the given type.  Remember that events are case sensitive by default.  Event name is the only required argument, you can optionally pass a struct of arguments to be passed to the listener by name.  Remember that you cannot depend on positional arguments in listeners.  The special argument __eventName will always be passed to the listeners.  You can override this in the arguments struct if you know what you are doing.
You can also provide the eventName argument as an array of event names to fire multiple events with the same argument collection.

__dispatch (required string eventName, [optional arguments struct])__

Alias for emit().

__async (required any f)__

Convenience method.  Give it a function, it will run it in a separate thread.

__pipeline ()__

Sometimes you need to have multiple event listeners that need to run, but you need to make sure they run in succession.
In the case of sync, listeners will be executed in the order they were attached.  But in the case of async, there are no guarantees of order, in fact all listeners may be executed at the same time.
In either scenario, use pipeline() to guarantee execution order.  Pipeline() will return an _object_ of sorts that has a few methods
add(function) will allow you to add a listener function, just like normal.  add() returns the pipeline object, allowing you to chain multiple add's together.
Once you have added all of your function handlers, call complete() to seal the pipeline.  This ensures that you have everything in the pipeline before execution.
At this point, you can use the pipeline _object_ as a listener function itself in on(), such as .on('event', pipelineObject);
Then when the listener is executed, all of the methods in the pipeline will be executed in order.  Remember that the functions you add to the pipeline can be closures - they can modify state one after another.
You can also call run() on a pipeline _object_ to execute it immediately, synchronously.  run() returns void.
You can call isComplete() on a pipeline _object_.
using a pipeline in an async listener (e.g.: on('asyncEvent', pipeline, true)), the pipeline as a whole will be execute asynchronously, but the functions added to the pipeline will still be executed in order.

Note: technically, the pipeline _object_ isn't an object, it is a struct full of methods.  This shouldn't affect how you work with the pipeline in any way.

__makeEmitter(required target)__

There are situations where you want to use events in legacy applications, where you can't make an object extend emit, possibly because it is already extending something else.
Because you can dispatch events for an object from outside of the object itself, you can use this method to make any object into an event emitter (as long as it does not have any existing method names that conflict).
Pass in an instance of an object, and emit will inject everything necessary to make that object work as an event emitter, just as if you had extended emit directly.

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

