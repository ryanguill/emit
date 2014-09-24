/*
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

	private function _normalizeEventName (required string eventName) {
		_ensurePrivateVariables();
		if (!_emit.caseSensitiveEventName) {
			return ucase(eventName);
		}
		return eventName;
	}

	function setMaxListeners (required numeric n) {
		_ensurePrivateVariables();
		if (int(n) != n || n < 1) {
			throw(type="Emit.InvalidMaxListeners", message="maxListeners must be a positive integer");
		}
		_emit.maxListeners = n;
	}

	function getMaxListeners () {
		_ensurePrivateVariables();
		return _emit.maxListeners;
	}

	function setCaseSensitiveEventName (required boolean value) {
		_ensurePrivateVariables();
		_emit.caseSensitiveEventName = value;
	}

	function isCaseSensitiveEventName () {
		_ensurePrivateVariables();
		return _emit.caseSensitiveEventName;
	}

	function addEventListener (required string eventName, required any listener, boolean async = false, numeric timesToListen = -1) {
		_ensurePrivateVariables();

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

		emit("newListener", listener);

		return this;
	}

	function on (required string eventName, required any listener, boolean async = false) {
		return addEventListener(argumentCollection=arguments);
	}

	function once (required string eventName, required any listener, boolean async = false) {
		_ensurePrivateVariables();
		addEventListener(eventName, listener, async, 1);
	}

	function many (required string eventName, required any listener, required numeric timesToListen, boolean async = false ) {
		_ensurePrivateVariables();
		if (int(timesToListen) != timesToListen || timesToListen < 1) {
			throw(type="Emit.InvalidTimesToListen", message="timesToListen must be a positive integer");
		}
		addEventListener(eventName, listener, async, timesToListen);
	}

	function removeListener (required string eventName, required any listener) {
		_ensurePrivateVariables();

		eventName = _normalizeEventName(eventName);

		if (structKeyExists(_emit.listeners, eventName)){

			for (var i = 1; i <= arrayLen(_emit.listeners[eventName]); i++) {
				if (listener.equals(_emit.listeners[eventName][i].listener)) {
					emit("removeListener", _emit.listeners[eventName][i].listener);
					arrayDeleteAt(_emit.listeners[eventName], i);

					return true;
				}
			}

		}

		return false;
	}

	function off (required string eventName, required any listener) {
		removeListener(argumentCollection=arguments);
	}

	function removeAllListeners (required string eventName) {
		_ensurePrivateVariables();

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

	function listeners (required string eventName) {
		_ensurePrivateVariables();

		eventName = _normalizeEventName(eventName);

		if (!structKeyExists(_emit.listeners, eventName)) {
			return [];
		}

		return duplicate(_emit.listeners[eventName]);
	}

	function emit (required string eventName) {
		_ensurePrivateVariables();

		eventName = _normalizeEventName(eventName);

		var localEventName = eventName;

		if (!structKeyExists(_emit.listeners, eventName)) {
			return false;
		}

		var listeners = _emit.listeners[eventName];

		if (!arrayLen(listeners)) {
			return false;
		}

		structDelete(arguments, "eventName");

		for (var listener in listeners) {


				//this is a regular listener
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
							listener.listener.run(argumentCollection=arguments);
						} else {
							listener.listener(argumentCollection=arguments);
						}
					} catch (any e) {
						arguments.exception = e;
						if (localEventName != "error") {
							dispatchError(argumentCollection=arguments);
						} else {
							arguments.skipErrorEvent = true;
							dispatchError(argumentCollection=arguments);
						}
					}
				}


			if (listener.timesToListen != -1) {
				listener.timesToListen--;
				if (listener.timesToListen < 1) {
					removeListener(localEventName, listener.listener);
				}
			}
		}

		return true;
	}

	function dispatch (required string eventName) {
		return emit(argumentCollection=arguments);
	}

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

	private boolean function _isPipeline (required any listener) {
		return isStruct(listener) && structKeyExists(listener, "type") && listener.type == "PIPELINE";
	}

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
			run = function() {
				if (!isComplete) {
					throw(type="Emit.pipelineNotComplete", message="You must call complete() on the pipeline when you are done adding listeners");
				}
				var args = arguments;

				for (var f in q) {
					f(argumentCollection=args);
				}

			}
		};

		return o;
	}

	function dispatchError () {
		param name="arguments.skipErrorEvent" default="false";
		if (structKeyExists(_emit.listeners, "error") && arrayLen(_emit.listeners["error"]) && !skipErrorEvent) {
			arguments.eventName = "error";
			return emit(argumentCollection=arguments);
		}

		if (structKeyExists(arguments, "exception")) {
			throw(arguments.exception);
		} else if (structKeyExists(arguments, "message")) {
			throw(message=message);
		} else {
			throw(type="Emit.unknownException", message="Unhandled Exception");
		}

	}

}