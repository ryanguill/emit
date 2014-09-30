component extends="testbox.system.BaseSpec" {

	function beforeTests() {
		//create a folder for the test files to be written to
		var tempDir = getTempDirectory();
		if (!findNoCase(right(tempDir, 1), "/\")) {
			tempDir &= "/";
		}

		variables.dir = tempDir & "emitBasicTest" & dateFormat(now(),"yyyymmdd") & timeformat(now(),"HHmmssl");

		directoryCreate(dir);

		writeoutput(dir & "<hr>");

	}

	function afterTests() {
		//attempt to clean up
		try {
			if (directoryExists(dir)) {
				directoryDelete(dir);
			}
		} catch (any e) {}
	}

	function setup (currentMethod) {
		testService = new com.testService();
	}

	function teardown (currentMethod) {

	}

	function testExtendsEmit() {
		$assert.instanceOf(testService, "lib.emit", "testService is not extending emit");
	}

	function testSimpleSync () {
		var output = [];

		testService.on("myEvent", function() {
			arrayAppend(output, "myEventHandler");
		});

		testService.on("myEvent", function() {
			arrayAppend(output, "myEventHandler2");
		});

		assert(arrayLen(output) == 0);

		testService.emit("myEvent");

		assert(arrayLen(output) == 2);

	}

	function testEmitDirectly () {
		var emit = new lib.emit();

		var output = [];

		emit.on("myEvent", function() {
			arrayAppend(output, "myEventHandler");
		});

		emit.on("myEvent", function() {
			arrayAppend(output, "myEventHandler2");
		});

		assert(arrayLen(output) == 0);

		emit.emit("myEvent");

		assert(arrayLen(output) == 2);

	}

	function testOnSync () {

		testService.on("testOnSync", function() {
			writeoutput("testOnSyncSuccess");
		});

		savecontent variable="local.outputData" {
			testService.emit("testOnSync");
		}

		assert(local.outputData == "testOnSyncSuccess");
	}

	function testMultipleListeners () {

		var testResult = false;

		testService.on(["test1","test2"], function() {
			writeoutput(__eventName);
		});

		savecontent variable="local.outputData" {
			testResult = testService.emit("test1");
		}

		assert(local.outputData == "test1");
		assert(testResult);

		savecontent variable="local.outputData" {
			testResult = testService.emit("test2");
		}

		assert(local.outputData == "test2");
		assert(testResult);

		savecontent variable="local.outputData" {
			testResult = testService.emit("test");
		}

		assert(local.outputData == "");
		assert(!testResult);

	}

	function testAddEventListenerSync () {

		testService.on("testAddEventListenerSync", function() {
			writeoutput("testAddEventListenerSyncSuccess");
		});

		savecontent variable="local.outputData" {
			testService.emit("testAddEventListenerSync");
			testService.emit("testAddEventListenerSync");
		}

		assert(local.outputData == repeatString("testAddEventListenerSyncSuccess",2));
	}

	function testOnceSync () {

		testService.once("testOnceSync", function() {
			writeoutput("testOnceSyncSuccess");
		});

		savecontent variable="local.outputData" {
			testService.emit("testOnceSync");
			testService.emit("testOnceSync");
		}

		assert(local.outputData == "testOnceSyncSuccess");

		assert(arrayLen(testService.listeners("testOnceSync")) == 0);

		testService.addEventListener("testAddEventListenerSync", function() {
			writeoutput("testAddEventListenerSyncSuccess");
		}, false, 2);

		savecontent variable="local.outputData" {
			testService.emit("testAddEventListenerSync");
			testService.emit("testAddEventListenerSync");
			testService.emit("testAddEventListenerSync");
		}

		assert(local.outputData == repeatString("testAddEventListenerSyncSuccess", 2));

		assert(arrayLen(testService.listeners("testAddEventListenerSync")) == 0);

	}

	function testManySync () {

		testService.many("testManySync", function() {
			writeoutput("testManySyncSuccess");
		}, 2);

		savecontent variable="local.outputData" {
			testService.emit("testManySync");
			testService.emit("testManySync");
			testService.emit("testManySync");
		}

		assert(local.outputData == repeatString("testManySyncSuccess", 2));

		assert(arrayLen(testService.listeners("testManySync")) == 0);

		$assert.throws(
			function() {
				testService.many("SomeEvent", function(){}, 0);
			}, "Emit.InvalidTimesToListen");

		$assert.throws(
			function() {
				testService.many("SomeEvent", function(){}, 1.5);
			}, "Emit.InvalidTimesToListen");

		$assert.throws(
			function() {
				testService.many("SomeEvent", function(){}, -2);
			}, "Emit.InvalidTimesToListen");
	}

	function testMaxListeners () {

		assert(testService.getMaxListeners() == 10);

		for (var i = 1; i <= 10; i++) {
			testService.on("testMaxListenersEvent", function(){});
		}

		$assert.throws(function () {
			testService.on("testMaxListenersEvent", function(){});
		}, "Emit.maxListenersExceeded");

		$assert.throws(function () {
			testService.addEventListener("testMaxListenersEvent", function(){});
		}, "Emit.maxListenersExceeded");

		testService.setMaxListeners(12);

		assert(testService.getMaxListeners() == 12);

		testService.on("testMaxListenersEvent", function(){});
		testService.addEventListener("testMaxListenersEvent", function(){});

		$assert.throws(function () {
			testService.on("testMaxListenersEvent", function(){});
		}, "Emit.maxListenersExceeded");

		$assert.throws(function () {
			testService.addEventListener("testMaxListenersEvent", function(){});
		}, "Emit.maxListenersExceeded");

		$assert.throws(function () {
			testService.setMaxListeners(0);
		}, "Emit.InvalidMaxListeners");

		$assert.throws(function () {
			testService.setMaxListeners(1.5);
		}, "Emit.InvalidMaxListeners");

	}

	function testCaseSensitivity() {

		assert(testService.isCaseSensitiveEventName() == true);

		var count = 0;

		testService.on("lowercaseevent1", function() {
			count++;
		});

		testService.emit("LOWERCASEEVENT1");

		assert(count == 0);

		testService.emit("LowerCaseEvent1");

		assert(count == 0);

		testService.emit("lowercaseevent1");

		assert(count == 1);

		//--------------------------

		testService.setCaseSensitiveEventName(true);

		assert(testService.isCaseSensitiveEventName() == true);

		var count = 0;

		testService.on("lowercaseevent2", function() {
			count++;
		});

		testService.emit("LOWERCASEEVENT2");

		assert(count == 0);

		testService.emit("LowerCaseEvent2");

		assert(count == 0);

		testService.emit("lowercaseevent2");

		assert(count == 1);

		//--------------------------

		testService.setCaseSensitiveEventName(false);

		assert(testService.isCaseSensitiveEventName() == false);

		var count = 0;

		testService.on("lowercaseevent3", function() {
			count++;
		});

		testService.emit("LOWERCASEEVENT3");

		assert(count == 1);

		testService.emit("LowerCaseEvent3");

		assert(count == 2);

		testService.emit("lowercaseevent3");

		assert(count == 3);

	}

	function testNewListenerEvent () {

		savecontent variable="local.testoutput" {
			testService.on("newListener", function() {
				writeOutput("newListenerFired");
			});
		}

		assert(local.testOutput == "newListenerFired");

		savecontent variable="local.testoutput" {
			testService.on("SomeEvent", function() {});
		}

		assert(local.testOutput == "newListenerFired");


	}

	function testRemoveListenerEvent () {

		testService.on("removeListener", function() {
			writeOutput("removeListenerFired");
		});

		var handler = function () {};

		testService.on("SomeEvent", handler);

		savecontent variable="local.output1" {
			testService.removeListener("SomeEvent", handler);
		}

		assert(local.output1 == "removeListenerFired");

		savecontent variable="local.output2" {
			testService.removeListener("SomeEvent", handler);
		}

		assert(local.output2 == "");

		//test removing a different listener
		testService.on("SomeEvent", function(){});

		savecontent variable="local.output3" {
			testService.removeListener("SomeEvent", function(){});
		}

		assert(local.output3 == "");

		//add a bunch and test remove all

		testService.on("SomeOtherEvent", function(){});
		testService.on("SomeOtherEvent", function(){});
		testService.on("SomeOtherEvent", function(){});
		testService.on("SomeOtherEvent", function(){});
		testService.on("SomeOtherEvent", function(){});

		savecontent variable="local.output4" {
			testService.removeAllListeners("SomeOtherEvent");
		}

		assert(local.output4 == repeatString("removeListenerFired", 5), local.output4);

	}


	function testOff () {

		testService.on("removeListener", function() {
			writeOutput("removeListenerFired");
		});

		var handler = function () {};

		testService.on("SomeEvent", handler);

		savecontent variable="local.output1" {
			testService.off("SomeEvent", handler);
		}

		assert(local.output1 == "removeListenerFired");

		savecontent variable="local.output2" {
			testService.off("SomeEvent", handler);
		}

		assert(local.output2 == "");
	}

	function testMultipleRemoveAllListeners () {

		testService.on("test1", function() {});

		testService.on("test2", function() {});

		assert(arrayLen(testService.listeners("test1")) == 1);
		assert(arrayLen(testService.listeners("test2")) == 1);

		testService.removeAllListeners(["test1","test2"]);

		assert(arrayLen(testService.listeners("test1")) == 0);
		assert(arrayLen(testService.listeners("test2")) == 0);
	}

	function testMultipleRemoveListeners () {

		var handler = function(){};

		testService.on(["multipleRemoveListenersEvent1", "multipleRemoveListenersEvent2"], handler);

		assert(arrayLen(testService.listeners("multipleRemoveListenersEvent1")) == 1);
		assert(arrayLen(testService.listeners("multipleRemoveListenersEvent2")) == 1);

		testService.removeListener(["multipleRemoveListenersEvent2","multipleRemoveListenersEvent1"], handler);

		assert(arrayLen(testService.listeners("multipleRemoveListenersEvent1")) == 0);
		assert(arrayLen(testService.listeners("multipleRemoveListenersEvent2")) == 0);
	}

	function testListeners () {

		var handler = function(){};

		testService.on("testEvent", handler);
		testService.on("testEvent", function(){});
		testService.on("testEvent", function(){});

		assert(arrayLen(testService.listeners("testEvent")) == 3);
		assert(arrayLen(testService.listeners("testOtherEvent")) == 0);

		testService.removeListener("testEvent", handler);

		assert(arrayLen(testService.listeners("testEvent")) == 2);

		testService.removeAllListeners("testEvent");

		assert(arrayLen(testService.listeners("testEvent")) == 0);

	}

	function testError () {

		var handler = function(exception) {
			writeoutput(exception.type);
		};

		testService.on("error", handler);

		testService.on("testErrorEvent", function() {
			var x = doesntExist;
		});

		savecontent variable="local.testOutput" {
			testService.emit("testErrorEvent");
		}

		assert(local.testOutput == "expression");

		testService.removeListener("error", handler);

		$assert.throws(function() {
			testService.emit("testErrorEvent");
		});

	}

	function testPipelineEventSync () {

		var test = [];

		var p = testService.pipeline().add(
			function() {
				arrayAppend(test, 1);
			}
		).add(
			function() {
				arrayAppend(test, 2);
			}
		).add(
			function() {
				arrayAppend(test, 3);
			}
		).add(
			function() {
				arrayAppend(test, 4);
			}
		).complete();

		testService.on("testPipeline", p);

		assert(arrayLen(test) == 0);

		testService.emit("testPipeline");

		assert(arrayLen(test) == 4);
		assert(arrayToList(test) == "1,2,3,4");

	}

	function testPipelineImmediateSync () {

		var test = [];

		testService.pipeline().add(
			function() {
				arrayAppend(test, 1);
			}
		).add(
			function() {
				arrayAppend(test, 2);
			}
		).add(
			function() {
				arrayAppend(test, 3);
			}
		).add(
			function() {
				arrayAppend(test, 4);
			}
		).complete().run();

		assert(arrayLen(test) == 4);
		assert(arrayToList(test) == "1,2,3,4");

	}

	function testMutatingState () {

		//the scenario here is that you are inside of a service and you want to
		//provide a way for users outside of the service to extend or intercept
		//some functionality.

		var inputData = {foo = "bar"};

		testService.on("extensionPointEvent", function(data) {
			data.newKey = "newValue";
		});

		var outputData = testService.extensionPoint(inputData);

		assert(structKeyExists(outputData, "foo"));
		assert(outputData.foo == "bar");

		assert(structKeyExists(outputData, "newKey"));
		assert(outputData.newKey == "newValue");

	}

	function testImplicitEventNameArgument () {

		testService.on("testEvent", function() {
			writeoutput(__eventName);
		});

		savecontent variable="local.outputData" {
			testService.emit("testEvent");
		}

		assert(local.outputData == "testEvent");

		assert(local.outputData == "testEvent");

		savecontent variable="local.outputData" {
			testService.emit("testEvent", {__eventName="foobar"});
		};

		assert(local.outputData == "foobar");

		testService.on("testEvent2", function() {
			writeoutput(structKeyList(arguments));
		});

		savecontent variable="local.outputData" {
			testService.emit("testEvent2");
		};

		assert(local.outputData == "__eventName");

		savecontent variable="local.outputData" {
			testService.emit("testEvent2", {foo="bar"});
		};

		assert(findNoCase("__eventName",local.outputData));
		assert(findNoCase("foo",local.outputData));

	}



	function testEmit () {

		var result = testService.emit("noListeners");

		assert(!result);

		testService.on("someEvent", function(){});

		result = testService.emit("someEvent");

		assert(result);

		testService.on("someEvent", function(){});

		result = testService.emit("someEvent");

		assert(result);

		testService.removeAllListeners("someEvent");

		result = testService.emit("someEvent");

		assert(!result);

	}

	function testMultipleEmit () {

		testService.on("multipleEmit1", function(){
			writeoutput(arguments.__eventName);
		});

		savecontent variable="local.output" {
			var result = testService.emit(["multipleEmit1", "multipleEmit2"]);
		}

		assert(result);
		assert(local.output == "multipleEmit1");

		testService.on("multipleEmit2", function(){
			writeoutput(arguments.__eventName);
		});

		savecontent variable="local.output" {
			result = testService.emit(["multipleEmit2", "multipleEmit1"]);
		}

		assert(result);
		assert(findNoCase("multipleEmit1", local.output));
		assert(findNoCase("multipleEmit2", local.output));
	}

	function testMultipleDispatch () {

		testService.on("multipleDispatch1", function(){
			writeoutput(arguments.__eventName);
		});

		savecontent variable="local.output" {
			var result = testService.dispatch(["multipleDispatch1", "multipleDispatch2"]);
		}

		assert(result);
		assert(local.output == "multipleDispatch1");

		testService.on("multipleDispatch2", function(){
			writeoutput(arguments.__eventName);
		});

		savecontent variable="local.output" {
			result = testService.dispatch(["multipleDispatch2", "multipleDispatch1"]);
		}

		assert(result);
		assert(findNoCase("multipleDispatch2", local.output));
		assert(findNoCase("multipleDispatch1", local.output));
	}

	function testDispatch () {

		var result = testService.dispatch("noListeners");

		assert(!result);

		testService.on("someEvent", function(){});

		result = testService.dispatch("someEvent");

		assert(result);

		testService.on("someEvent", function(){});

		result = testService.dispatch("someEvent");

		assert(result);

		testService.removeAllListeners("someEvent");

		result = testService.dispatch("someEvent");

		assert(!result);

	}

	function testComposingServices () {

		//the scenario here is that you want to wire multiple services together to
		//act on a struct of data.

		var formatterService = new com.formatterService();

		testService.on("testCompose", formatterService.formatName);

		var inputData = {firstname="Ryan", lastname="Guill"};

		testService.emit("testCompose", {data=inputData});

		assert(structKeyExists(inputData, "fullname"));
		assert(inputData.fullname == "Guill, Ryan");

	}

	function testAsync () {
		var filename = dir & "/testAsync.txt";

		testService.async(function () {
			filewrite(filename, "");
		});

		//just to be sure
		sleep(10);

		assert(fileExists(filename));
	}

	function testOnAsync () {
		var filename = dir & "/testOnAsync.txt";

		var x = randRange(0,1000);

		testService.on("testOnAsync", function () {
			filewrite(filename, x);
		});


		testService.emit("testOnAsync");

		//just to be sure
		sleep(10);

		assert(fileExists(filename));

		var filecontents = fileRead(filename);

		assert(filecontents == x);

	}

	function testPipelineEventAsync () {

		var test = [];

		var filename = dir & "/testPipelineEventAsync.txt";

		var p = testService.pipeline().add(
			function() {
				arrayAppend(test, 1);
			}
		).add(
			function() {
				arrayAppend(test, 2);
			}
		).add(
			function() {
				arrayAppend(test, 3);
			}
		).add(
			function() {
				arrayAppend(test, 4);
			}
		).add(
			function() {
				filewrite(filename, arrayToList(test));
			}
		).complete();

		testService.on("testPipelineEventAsync", p, true);

		testService.emit("testPipelineEventAsync");

		sleep(10);

		assert(fileExists(filename));

		var filecontents = fileRead(filename);

		assert(filecontents == "1,2,3,4", filecontents);

	}


}
































