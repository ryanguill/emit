/*
Copyright 2014-5 Ryan Guill

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

========================================================================================================================

See documentation at https://github.com/ryanguill/emit
*/

component {

	//intentionally don't use an init method so that subclasses do not have to call super.init()

	private function _ensurePrivateVariables () {
		if (!structKeyExists(variables, "_emit")) {
			variables._emit = {};
			_emit.listeners = createObject("java", "java.util.LinkedHashMap").init();
			_emit.maxListeners = 10;
			_emit.caseSensitiveEventName = true;
		}
	}

	private function _normalizeEventName (required any eventName) {
		_ensurePrivateVariables();

		if (!isSimpleValue(eventName)) {
			throw(type="Emit.invalidEventName", message="Invalid Event Name");
		}

		if (!_emit.caseSensitiveEventName) {
			return ucase(eventName);
		}
		return eventName;
	}

	/*
		Set the maximum listeners per event. You must do this per instance of emit (or subclass). See getMaxListeners().
	*/
	function setMaxListeners (required numeric n) {
		_ensurePrivateVariables();
		if (int(n) != n || n < 1) {
			throw(type="Emit.InvalidMaxListeners", message="maxListeners must be a positive integer");
		}
		_emit.maxListeners = n;
	}

	/*
		By default, there is a limit of 10 listeners on a given event. This is to help identify memory leaks and
		listeners that are not being removed properly. This will not be appropriate for all applications.
		use setMaxListeners() to set to an appropriate level for your needs. If you try to add an event listener
		which exceeds the limit, an exception of type Emit.maxListenersExceeded will be thrown.
	*/
	function getMaxListeners () {
		_ensurePrivateVariables();
		return _emit.maxListeners;
	}


	/*
		see isCaseSensitiveEventName()
	*/
	function setCaseSensitiveEventName (required boolean value) {
		_ensurePrivateVariables();
		_emit.caseSensitiveEventName = value;
	}

	/*
		By default, emit treats event names as case sensitive. This method returns true by default.
		use setCaseSensitiveEventName() to override. You must do this per instance of emit (or subclass).
	*/
	function isCaseSensitiveEventName () {
		_ensurePrivateVariables();
		return _emit.caseSensitiveEventName;
	}


	/*
		Creates an event listener for a particular event emitted by the instance that you are calling
		addEventListener on. Event is case sensitive by default. Listener can be any custom function.
		Async defaults to false. If you use async true, the listener will be executed in a separate thread.
		Keep the following in mind:

		Event names must be a string.
		You will not be guaranteed that it will run at any particular time or order.
		You will not be able to send data into the output buffer. This makes debugging difficult - use logging or
			write out files.
		You will have access to the data that you close over inside of your listener. Make sure you have everything
			you need.
		You cannot use positional arguments in listeners. Only depend on named arguments. You can depend on named
			arguments that are not defined in the method definition though.
		timesToListen defaults to -1, which means it will listen until manually removed - setting it to 1 will
			automatically remove the event listener the first time it is called. Useful for fire once async handling.

		You can also provide the eventName argument as an array of event names to listen on multiple events with the
		same handler.

		If you try to add an event listener which exceeds the limit, an exception of type Emit.maxListenersExceeded
		will be thrown. See setMaxListeners(). See also many().
	*/
	function addEventListener (required any eventName, required any listener, boolean async = false, numeric timesToListen = -1) {
		_ensurePrivateVariables();

		if (isArray(eventName)) {
			for (var en in eventName) {
				addEventListener(en, listener, async, timesToListen);
			}

			return this;
		}

		if (timesToListen != -1 && (int(timesToListen) != timesToListen || timesToListen < 1)) {
			throw(type="Emit.InvalidTimesToListen", message="timesToListen must be a positive integer");
		}

		eventName = _normalizeEventName(eventName);

		if (!structKeyExists(_emit.listeners, eventName)) {
			_emit.listeners[eventName] = [];
		}

		if (arrayLen(_emit.listeners[eventName]) >= getMaxListeners()) {
			throw(type="Emit.maxListenersExceeded", message="Max Listeners exceeded for eventName: " & eventName, detail="Current Max Listeners value: " & getMaxListeners());
		}

		if (_isPipeline(listener)) {
			if (!listener.isComplete()) {
				throw(type="Emit.pipelineNotComplete", message="You must call complete() on the pipeline when you are done adding listeners");
			}
		}

		arrayAppend(_emit.listeners[eventName], {listener=listener, async=async, timesToListen=timesToListen});

		emit("newListener", {listener=listener});

		return this;
	}

	/*
		Alias for addEventListener().
	*/
	function on (required any eventName, required any listener, boolean async = false) {
		return addEventListener(argumentCollection=arguments);
	}

	/*
		Alias for addEventListener() with timesToListen = 1.
	*/
	function once (required any eventName, required any listener, boolean async = false) {
		_ensurePrivateVariables();
		addEventListener(eventName, listener, async, 1);
	}

	/*
		Alternative to addEventListener, useful for quickly setting a certain number of times to fire a particular listener.
	*/
	function many (required any eventName, required any listener, required numeric timesToListen, boolean async = false ) {
		_ensurePrivateVariables();
		addEventListener(eventName, listener, async, timesToListen);
	}

	/*
		To remove a listener, you must pass in the exact listener you used to add the event listener initially.
		Which means if you intend to remove a listener you need to create the listener in a separate variable and
		use it to both add and remove.

		You can also provide the eventName argument as an array of event names to remove the same handler from
		multiple events. This is only useful if you used the exact same handler for multiple events.
	*/
	function removeListener (required any eventName, required any listener) {
		_ensurePrivateVariables();

		if (isArray(eventName)) {
			var output = false;
			for (var en in eventName) {
				output = removeListener(en, listener) || output;
			}
			return output;
		}

		eventName = _normalizeEventName(eventName);

		if (structKeyExists(_emit.listeners, eventName)){

			for (var i = 1; i <= arrayLen(_emit.listeners[eventName]); i++) {
				if (listener.equals(_emit.listeners[eventName][i].listener)) {
					emit("removeListener", {listener=_emit.listeners[eventName][i].listener});
					arrayDeleteAt(_emit.listeners[eventName], i);

					return true;
				}
			}
		}

		return false;
	}

	/*
		Alias for removeListener();
	*/
	function off (required any eventName, required any listener) {
		removeListener(argumentCollection=arguments);
	}

	/*
		Removes all listeners for a given event. You can also provide the eventName argument as an array of event
		names to remove all listeners from multiple events.
	*/
	function removeAllListeners (required any eventName) {
		_ensurePrivateVariables();

		if (isArray(eventName)) {
			for (var en in eventName) {
				removeAllListeners(en);
			}
			return this;
		}

		eventName = _normalizeEventName(eventName);

		if (structKeyExists(_emit.listeners, eventName)){
			var len = arrayLen(_emit.listeners[eventName]);
			var count = 0;
			while (arrayLen(_emit.listeners[eventName]) > 0) {
				removeListener(eventName, _emit.listeners[eventName][1].listener);
				if (++count > len) {
					//just to protect against an endless loop
					abort;
				}
			}
		}

		return this;
	}

	/*
		Gets an array of all of the listeners. Each item in the array is a structure with the keys:
		listener (function), async (boolean), and once (boolean);
	*/
	function listeners (required string eventName) {
		_ensurePrivateVariables();

		eventName = _normalizeEventName(eventName);

		if (!structKeyExists(_emit.listeners, eventName)) {
			return [];
		}

		return duplicate(_emit.listeners[eventName]);
	}

	/*
		Fires an event of the given type. Remember that events are case sensitive by default.
		Event name is the only required argument, you can optionally pass a struct of arguments to be passed to
		the listener by name. Remember that you cannot depend on positional arguments in listeners. The special
		argument __eventName will always be passed to the listeners. You can override this in the arguments struct if
		you know what you are doing. You can also provide the eventName argument as an array of event names to fire
		multiple events with the same argument collection.
	*/
	function emitx (required any eventName, struct args = {}) {
		_ensurePrivateVariables();

		if (isArray(eventName)) {
			var output = false;
			for (var en in eventName) {
				output = emit(en, duplicate(args)) || output;
			}
			return output;
		}

		eventName = _normalizeEventName(eventName);

		param name="args.__eventName" default=arguments.eventName;

		if (!structKeyExists(_emit.listeners, eventName)) {
			return false;
		}

		var listeners = _emit.listeners[eventName];

		if (!arrayLen(listeners)) {
			return false;
		}

		for (var listener in listeners) {
			if (listener.async) {
				if (_isPipeline(listener.listener)) {
					arguments.f = listener.listener.run;
				} else {
					arguments.f = listener.listener;
				}
				async(argumentCollection=arguments);
			} else {
				try {
					if (_isPipeline(listener.listener)) {
						listener.listener.run(argumentCollection=args);
					} else {
						listener.listener(argumentCollection=args);
					}
				} catch (any e) {
					args.exception = e;
					if (eventName != "error") {
						dispatchError(args);
					} else {
						args.skipErrorEvent = true;
						dispatchError(args);
					}
				}
			}

			if (listener.timesToListen != -1) {
				listener.timesToListen--;
				if (listener.timesToListen < 1) {
					removeListener(eventName, listener.listener);
				}
			}
		}

		return true;
	}

	/*
		Alias for emit().
	*/
	function dispatch (required any eventName, struct args = {}) {
		return emit(argumentCollection=arguments);
	}


	/*
		Convenience method. Give it a function, it will run it in a separate thread.
		Only use for side effect methods that return void or that you don't want the result from.
		See also future() and promise().
	*/
	function async (required any f) {
		var listener = f;
		structDelete(arguments, "f");

		thread action="run" name="thread_#createUUID()#" listener=listener args=arguments emit=this {
			try {
				listener(argumentCollection=arguments);
			} catch (any e) {
				arguments.exception = e;
				emit.dispatchError(argumentCollection=arguments);
			}
		}
	}

	private boolean function _isFuture (required any value) {
		return isStruct(value) && structKeyExists(value, "type") && value.type == "FUTURE";
	}

	/*
		todo: future() documentation
	*/
	//todo: allow future to take a second argument for lazy evaluation
	function future(required any f) {
		var listener = f;
		structDelete(arguments, "f");

		var threadName = "future" & createUUID();

		thread action="run" name=threadName listener=listener args=arguments emit=this {
			thread.err = {};
			try {
				thread.result = listener(argumentCollection=arguments);
			} catch (any e) {
				thread.err = e;
			}
		}

		var hasJoined = false;
		var isComplete = false;
		var hasError = false;
		var result = "";
		var error = {};

		var o = {
			type: "FUTURE",
			isComplete: function () {
				if (!isComplete) {
					isComplete = cfthread[threadName]["STATUS"] == "COMPLETED";
				}
				return isComplete;
			},
			hasError: function() { return hasError; },
			get: function(numeric wait = 0) {
				if (!hasJoined) {
					thread action="join" name=threadName timeout=wait;
					var threadResult = cfthread[threadName];
					if (threadResult["STATUS"] == "COMPLETED") {
						if (!isNull(threadResult.err.code)) {
							hasError = true;
							error = threadResult.err;
							throw(threadResult.err);
						} else {
							result = threadResult.result;
						}

						isComplete = true;
						hasJoined = true;
					} else {
						//we didnt wait long enough...
						throw(type="TimeoutException", message="After waiting " & wait & "ms, the Future has still not completed. Try again later");
					}
				}

				return hasError ? error : result;
			}
		};

		return o;
	}

	private boolean function _isPromise (required any value) {
		return isStruct(value) && structKeyExists(value, "type") && value.type == "PROMISE";
	}

	/*
		todo: promise() documentation
	*/
	function promise (required any f) {

		var listener = f;
		structDelete(arguments, "f");

		var threadName = "promise" & createUUID();

		thread action="run" name=threadName listener=listener emit=this {
			thread.promiseStatus = "PENDING";

			var resolve = function (value) {
				thread.promiseStatus = "FULFILLED";
				thread.result = value;
			};
			var reject = function (value) {
				thread.promiseStatus = "REJECTED";
				thread.err = value;
				dump(thread);
				dump(value);abort;
			};

			try {
				listener(resolve, reject);
			} catch (any e) {
				reject(e);
			}
		}

		var hasJoined = false;
		var isComplete = false;
		var status = "PENDING"; //["PENDING","FULFILLED","REJECTED"]
		var result = "";
		var error = {};

		var join = function () {
			if (!hasJoined) {
				thread action="join" name=threadName timeout="0";
				var threadResult = cfthread[threadName];
				if (threadResult.promiseStatus == "REJECTED") {
					error = threadResult.err;
					status = "REJECTED";
				} else if (threadResult.promiseStatus == "FULFILLED") {
					result = threadResult.result;
					status = "FULFILLED";
				} else {
					//todo: they didn't call resolve or reject - what do?
				}

				isComplete = true;
				hasJoined = true;
			}
		};

		var o = {
			type: "PROMISE",
			getStatus: function () { return status; }, //todo: needs tests
			isComplete: function () { //todo: needs tests
				if (!isComplete) {
					isComplete = cfthread[threadName]["STATUS"] == "COMPLETED";
				}
				return isComplete;
			},
			then: function (any a, any b) {
				join();

				var tempResult = javacast("null", 0);

				if (isNull(a)) {
					//no args, do nothing
				} else if (isNull(b)) {
					//a = closure
					if (_canBeCalledAsFunction(a)) {
						if (status == "FULFILLED") {
							tempResult = a(result);
							if (isNull(tempResult)) {
								//do nothing
							} else if (_isPromise(tempResult)) {
								tempResult.then(function(value) {
									result = value;
								})
								.catch(function(value) {
									error = value;
									//not sure im doing the right thing here...
									status = "REJECTED";
								});
							} else {
								result = tempResult;
							}
						}
					} else {
						throw(message="If passing a single argument to then, it must be a closure.");
					}
				} else {
					//a = object, b = string
					if (isObject(a) && isSimpleValue(b) && structKeyExists(a, b)) {
						if (status == "FULFILLED") {
							tempResult = a[b](result);
							if (isNull(tempResult)) {
								//do nothing
							} else if (_isPromise(tempResult)) {
								tempResult.then(function(value) {
									result = value;
								})
								.catch(function(value) {
									error = value;
									//not sure im doing the right thing here...
									status = "REJECTED";
								});
							} else {
								result = tempResult;
							}
						}
					} else {
						throw(message="If passing two arguments to then, it must be an object and a string of the method name to call on the object");
					}
				}

				return o;
			},
			catch: function (any a, any b) {
				join();

				if (isNull(a)) {
					//no args, do nothing
				} else if (isNull(b)) {
					//a = closure
					if (_canBeCalledAsFunction(a)) {
						if (status == "REJECTED") {
							a(error);
						}
					} else {
						throw(message="If passing a single argument to catch, it must be a closure.");
					}
				} else {
					//a = object, b = string
					if (isObject(a) && isSimpleValue(b) && structKeyExists(a, b)) {
						if (status == "REJECTED") {
							a[b](error);
						}
					} else {
						throw(message="If passing two arguments to catch, it must be an object and a string of the method name to call on the object");
					}
				}



				return o;
			}
		};

		return o;
	}

	/*
		todo: all() documentation
	*/
	function all (required any collection) {

		if (!isArray(collection) && !isStruct(collection)) {
			throw(message="all(collection) // collection must be an array or a struct");
		}

		return promise(function (resolve, reject) {
			var o = [];

			if (isArray(collection)) {
				for (var p in collection) {
					if (_isPromise(p)) {
						p.then(function (value) {
							arrayAppend(o, value);
						}, function (value) {
							reject(value);
						});
					} else if (_isFuture(p)) {
						try {
							arrayAppend(o, p.get());
						} catch (any e) {
							reject(e);
						}
					} else {
						arrayAppend(o, p);
					}
				}
			} else { //must be struct
				o = {};
				for (var key in collection) {
					if (_isPromise(collection[key])) {
						collection[key].then(function (value) {
							o[key] = value;
						}, function (value) {
							reject(value);
						});
					} else if (_isFuture(collection[key])) {
						try {
							o[key] = collection[key].get();
						} catch (any e) {
							reject(e);
						}
					} else {
						o[key] = collection[key];
					}
				}
			}

			resolve(o);
		});
	}

	/*
		TODO: race() documentation
	*/
	function race (required any collection) {

		if (!isArray(collection) && !isStruct(collection)) {
			throw(message="race(collection) // collection must be an array or a struct");
		}

		return promise(function (resolve, reject) {
			if (isArray(collection)) {
				while (true) {
					for (var p in collection) {
						if (_isPromise(p) && p.isComplete()) {
							p.then(function (value) {
								return resolve(value);
							}, function (value) {
								return reject(value);
							});
						} else if (_isFuture(p) && p.isComplete()) {
							try {
								return resolve(p.get());
							} catch (any e) {
								return reject(e);
							}
						} else {
							return resolve(p);
						}
					}
				}

			} else { //must be struct
				while (true) {
					for (var key in collection) {
						if (_isPromise(collection[key]) && collection[key].isComplete()) {
							collection[key].then(function (value) {
								return resolve(value);
							}, function (value) {
								return reject(value);
							});
						} else if (_isFuture(collection[key]) && collection[key].isComplete()) {
							try {
								return resolve(collection[key].get());
							} catch (any e) {
								return reject(e);
							}
						} else {
							return resolve(collection[key]);
						}
					}
				}
			}
		});
	}


	private boolean function _isPipeline (required any value) {
		return isStruct(value) && structKeyExists(value, "type") && value.type == "PIPELINE";
	}

	/*
		Sometimes you need to have multiple event listeners that need to run, but you need to make sure they run
		in succession. In the case of sync, listeners will be executed in the order they were attached. But in the
		case of async there are no guarantees of order, in fact all listeners may be executed at the same time.

		In either scenario, use pipeline() to guarantee execution order.
		Pipeline() will return an object of sorts that has a few methods

		add(function) will allow you to add a listener function, just like normal. add() returns the pipeline object,
		allowing you to chain multiple add's together.

		Once you have added all of your function handlers, call complete() to seal the pipeline. This ensures that
		you have everything in the pipeline before execution.

		At this point, you can use the pipeline object as a listener function itself in on(), such as
		.on('event', pipelineObject); Then when the listener is executed, all of the methods in the pipeline will be
		executed in order. Remember that the functions you add to the pipeline can be closures - they can modify
		state one after another.

		You can also call run() on a pipeline object to execute it immediately, synchronously. run() returns void.

		You can call isComplete() on a pipeline object.

		Using a pipeline in an async listener (e.g.: on('asyncEvent', pipeline, true)), the pipeline as a whole will
		be execute asynchronously, but the functions added to the pipeline will still be executed in order.

		Note: technically, the pipeline object isn't an object, it is a struct full of methods. This should not affect
		how you work with the pipeline in any way.
	*/
	function pipeline () {
		var q = [];
		var isComplete = false;

		var callAsync = variables.async;
		
		var o = {
			type = "PIPELINE",
			add = function(required any f) {
				arrayAppend(q, f);
				return o;
			},
			complete = function() {
				isComplete = true;
				return o;
			},
			isComplete = function() {
				return isComplete;
			},
			run = function(struct args = {}) {
				if (!isComplete) {
					throw(type="Emit.pipelineNotComplete", message="You must call complete() on the pipeline when you are done adding listeners");
				}

				for (var f in q) {
					f(argumentCollection=args);
				}

			}
		};

		return o;
	}

	/*
		Convenience function for dispatching an event on "error". By default, any exceptions in the calling of the
		listener will redispatch to "error", with an added argument of exception. If no listeners exist for the
		"error" event, the exception is thrown.
	*/
	function dispatchError (struct args = {}) {
		param name="args.skipErrorEvent" default="false";
		if (structKeyExists(_emit.listeners, "error") && arrayLen(_emit.listeners["error"]) && !args.skipErrorEvent) {
			return emit("error", args);
		}

		if (structKeyExists(args, "exception")) {
			throw(args.exception);
		} else if (structKeyExists(args, "message")) {
			throw(message=message);
		} else {
			throw(type="Emit.unknownException", message="Unhandled Exception");
		}
	}

	private function _canBeCalledAsFunction(required any f) {
		return isCustomFunction(f) || isClosure(f);
	}

	private function __inject (required string name, required any f, required boolean isPublic) {
		if (isPublic) {
			this[name] = f;
			variables[name] = f;
		} else {
			variables[name] = f;
		}
	}

	private function __cleanup () {
		structDelete(variables, "__inject");
		structDelete(this, "__inject");
		structDelete(variables, "__cleanup");
		structDelete(this, "__cleanup");
	}

	/*
		There are situations where you want to use events in legacy applications where you can't make an object
		extend emit, possibly because it is already extending something else. Because you can dispatch events for an
		object from outside of the object itself, you can use this method to make any object into an event emitter
		(as long as it does not have any existing method names that conflict). Pass in an instance of an object,
		and emit will inject everything necessary to make that object work as an event emitter, just as if you
		had extended emit directly.
	*/
	function makeEmitter (required target) {

		//write the injector first
		target["__inject"] = variables["__inject"];
		target["__cleanup"] = variables["__cleanup"];

		//check to make sure that the target doesnt already have any of the functions we want to add
		var functionsNotToAdd = ["__inject","__cleanup","makeEmitter"];
		var functionsToAdd = [];

		var f = {};

		var sourceFunctions = getMetadata(this).functions;

		for (f in sourceFunctions) {
			if (!arrayFindNoCase(functionsNotToAdd, f.name)) {
				arrayAppend(functionsToAdd, f.name);
			}
		}

		for (f in getMetadata(target).functions) {
			if (arrayFindNoCase(functionsToAdd, f.name)) {
				throw(message="Error making target an event emitter, target already defines method: " & f.name);
			}
		}

		//now use our new inject function to put in the rest
		for (f in functionsToAdd) {
			var meta = getMetadata(variables[f]);
			//because cf be dumb
			param name="meta.access" default="public";
			target.__inject(f, variables[f], (meta.access == "public" ? true : false));
		}

		target.__cleanup();

		return target;
	}

}