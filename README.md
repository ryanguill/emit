emit
====

#CFML Event Emitter

The primary goal of this project is to be similar to the event emitter in node.js, although this project might deviate
in some ways from its api.  It also seeks to privide an easy way to create async code in cfml.  Any event listener can be created as async.

> Note! this project is just getting started.  Documentation and tests will be sparse for the time being.  Pull requests or issues for code, documentation or tests welcome!

I aim to support railo 4+ first, and ACF 10+ secondarily.  You could probably back-port this project to tag based to as far as CF 8 - this is left as an exercise for the cursed.  I am not interested in tag based pull requests for this project.

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

```
instance.addEventListener("eventName", function(data) {
    ...
});
```
	
Note: Event names are case sensitive by default.  You can call setCaseSensitiveEventNames(false) to change this.

Most functions return an instance of the object so that they can be chained.

##API:

```
addEventListener (required string event, required any listener, boolean async = false, boolean once = false)
```
Creates an event listener for a particular event emitted by the instance that you are calling addEventListener on.  Event is case sensitive by default.  Listener can be any custom function.  Async defaults to false.  If you use async true, the listener will be executed in a separate thread.  Keep the following in mind:

- You will not be guarenteed that it will run at any particular time or order.
- You will not be able to send data into the output buffer.  This makes debugging difficult - use logging or write out files.
- You will have access to the data that you close over inside of your listener.  Make sure you have everything you need.

Once defaults to false - setting once to true will automatically remove the event listener the first time it is called.  Useful for fire once async handling.

If you try to add an event listener which exceeds the limit, an exception of type Emit.Emit.maxListenersExceeded will be thrown. See setMaxListeners().

	
```
on (required string event, required any listener, boolean async = false)
```

Alias for addEventListener().

```
once (required string event, required any listener, boolean async = false)
```

Alias for addEventListner() with once=true.

```
removeListener (required string event, required any listener)
```

To remove a listener, you must pass in the exact listener you used to add the event listener initially.  Which means if you intend to remove a listener you need to create the listener in a separate variable and use it to both add and remove.

```
removeAllListeners (required string event)
```

Removes all listeners for a given event.

```
listeners (required string event)
```

Gets an array of all of the listeners.  Each item in the array is a structure with the keys: listner (function), async (boolean), and once (boolean);

```
emit(required string event)
```

Fires an event of the given type.  Remember that events are case sensitive by default.

```
dispatch (required string event)
```

Alias for emit().

```
dispatchError ()
```

Convenience function for dispatching an event on "error".  By default, any exceptions in the calling of the listener will redispatch to "error", with an added argument of *exception*.  If no listeners exist for the "error" event, the exception is thrown.  


Other Methods:

```
getMaxListeners ()
```

By default, there is a limit of 10 listeners on a given event.  This is to help identify memory leaks and to listeners that are not being removed properly.  This will not be appropriate for all applications.  use setMaxListeners() to set to an appropriate level for your needs.  If you try to add an event listener which exceeds the limit, an exception of type Emit.Emit.maxListenersExceeded will be thrown.


```
setMaxListeners (required numeric n)
```

Set the maximum listeners per event. You must do this per instance of emit (or subclass). See getMaxListeners().

```
isCaseSensitiveEventName ()
```

Be default, emit treats event names as case sensitive.  This method returns true by default.  use setCaseSensitiveEventName() to override.  You must do this per instance of emit (or subclass).

```
setCaseSensitiveEventName (required boolean value)
```

see isCaseSensitiveEventName().


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

