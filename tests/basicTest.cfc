component extends="testbox.system.BaseSpec" {

	function beforeTests() {
		//create a folder for the test files to be written to
		variables.dir = getTempDirectory() & "/emitBasicTest" & dateFormat(now(),"yyyymmdd") & timeformat(now(),"HHmmss");

		directoryCreate(dir);
	}

	function afterTests() {
		//attempt to clean up
		try {
			if (directoryExists(dir)) {
				directoryDelete(dir);
			}
		} catch (any e) {

		}
	}

	function setup (currentMethod) {

	}

	function teardown (currentMethod) {

	}

	function testSimpleSync () {
		var testService = new com.testService();

		$assert.instanceOf(testService, "lib.emit", "testService is not extending emit");

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
		var testService = new com.testService();

		testService.on("testOnSync", function() {
			writeoutput("testOnSyncSuccess");
		});

		savecontent variable="local.outputData" {
			testService.emit("testOnSync");
		}

		assert(local.outputData == "testOnSyncSuccess");

	}

	function testAddEventListenerSync () {
		var testService = new com.testService();

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
		var testService = new com.testService();

		testService.once("testOnceSync", function() {
			writeoutput("testOnceSyncSuccess");
		});

		savecontent variable="local.outputData" {
			testService.emit("testOnceSync");
			testService.emit("testOnceSync");
		}

		assert(local.outputData == "testOnceSyncSuccess");

		assert(arrayLen(testService.listeners("testOnceSync")) == 0);

	}

	function testMaxListeners () {
		var testService = new com.testService();

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
		}, "Emit.maxListenersExceeded")

		$assert.throws(function () {
			testService.setMaxListeners(0);
		}, "Emit.InvalidMaxListeners");

		$assert.throws(function () {
			testService.setMaxListeners(1.5);
		}, "Emit.InvalidMaxListeners");

	}

	function testCaseSensitivity() {

		var testService = new com.testService();

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
		var testService = new com.testService();

		testService.on("newListener", function() {
			writeOutput("newListenerFired");
		});

		savecontent variable="local.testoutput" {
			testService.on("SomeEvent", function() {});
		}

		assert(local.testOutput == "newListenerFired");
	}

	function testRemoveListenerEvent () {
		var testService = new com.testService();

		testService.on("removeListener", function() {
			writeOutput("removeListenerFired");
		});

		var handler = function () {}

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
		var testService = new com.testService();

		testService.on("removeListener", function() {
			writeOutput("removeListenerFired");
		});

		var handler = function () {}

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

	function testListeners () {
		var testService = new com.testService();

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

	function testDispatch () {
		var testService = new com.testService();

		testService.on("testDispatch", function() {
			writeoutput("testDispatchSuccess");
		});

		savecontent variable="local.outputData" {
			testService.dispatch("testDispatch");
		}

		assert(local.outputData == "testDispatchSuccess");

	}

	function testError () {

		var testService = new com.testService();

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
		}, "expression");

	}

	function testPipelineEventSync () {

		var testService = new com.testService();

		var test = [];

		testService.pipeline("testPipeline").add(
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

		assert(arrayLen(test) == 0);

		testService.emit("testPipeline");

		assert(arrayLen(test) == 4);
		assert(arrayToList(test) == "1,2,3,4");

	}

	function testPipelineImmediateSync () {

		var testService = new com.testService();

		var test = [];

		testService.pipeline("testPipeline").add(
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

		testService.emit("testPipeline");

		assert(arrayLen(test) == 8);
		assert(arrayToList(test) == "1,2,3,4,1,2,3,4");
	}

	function testPipelineEventAsync () {

		var testService = new com.testService();

		var test = [];

		var filename = expandPath(dir) & "/testPipelineEventAsync.txt";

		testService.pipeline("testPipelineEventAsync", true).add(
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

		testService.emit("testPipelineEventAsync");

		sleep(10);

		assert(fileExists(filename));

		var filecontents = fileRead(filename);

		assert(filecontents == "1,2,3,4", filecontents);

	}

	function testPipelineImmediateAsync () {

		var testService = new com.testService();

		var test = [];

		var filename = expandPath(dir) & "/testPipelineImmediateAsync.txt";

		testService.pipeline("testPipelineImmediateAsync", true).add(
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
		).complete().run();

		sleep(10);

		assert(fileExists(filename));

		var filecontents = fileRead(filename);

		assert(filecontents == "1,2,3,4", filecontents);

	}

	function testMutatingState () {

		/*
			the scenario here is that you are inside of a service and you want to
			provide a way for users outside of the service to extend or intercept
			some functionality.
		*/

		var testService = new com.testService();

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

	function testEmit () {
		var testService = new com.testService();

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

	function testDispatch () {
		var testService = new com.testService();

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

		/*
			the scenario here is that you want to wire multiple services together to
			act on a struct of data.
		*/
		var testService = new com.testService();
		var formatterService = new com.formatterService();

		testService.on("testCompose", formatterService.formatName);

		var inputData = {firstname="Ryan", lastname="Guill"};

		testService.emit("testCompose", inputData);

		assert(structKeyExists(inputData, "fullname"));
		assert(inputData.fullname == "Guill, Ryan");

	}

	function testAsync () {

		var testService = new com.testService();

		var filename = expandPath(dir) & "/testAsync.txt";

		testService.async(function () {
			filewrite(filename, "");
		});

		//just to be sure
		sleep(10);

		assert(fileExists(filename));
	}

	function testOnAsync () {

		var testService = new com.testService();

		var filename = expandPath(dir) & "/testOnAsync.txt";

		var x = randRange(0,1000);

		testService.on("testOnAsync", function () {
			filewrite(filename, x);
		}, true);


		testService.emit("testOnAsync");

		//just to be sure
		sleep(10);

		assert(fileExists(filename));

		var filecontents = fileRead(filename);

		assert(filecontents == x);

	}

}
































