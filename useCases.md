emit Use Cases
==============

##Project Goals

The two primary things that emit provides is:

1. An implementation of the observer pattern for event driven programming in CFML
2. Easy implementation of asynchronous programming

In the following sections I will attempt to explain these in more detail and to give some concrete examples of where these things can be useful.

##Concepts

If you have ever programmed in javascript or actionscript, you have likely done some event driven programming.  It is much more common in these languages, because it is a very useful concept for dealing with UI based events.  Any time you have use jquery's ```on()``` or just straight ```addEventListener``` you were doing event driven programming.  At its core, the idea is that something will broadcast out an event (and optionally associated data) and if anything else cares to know when that event occurs, they can register their interest and provide actions to perform in that case.  I want to click a button, and I want this to happen.

The first great part of event driven programming is that it provides an extension point that the original author didnt have to consider at the time the source was being designed or written, and it gives you a way to tie things together in a very loosely coupled way.  In javascript, the button does not require any knowledge of what my code intends to do when a button is clicked, it just has to broadcast out the information and it is up to the listener to do with that information what it will.  And if no-one is listening, that is okay too, nothing happens.

The second benefit is that many listeners can be added to the same event without changing the source of the event.  So today you know that you need to do y when x happens.  Later on the requirements change and you need to do z as well.  Now instead of changing the source, you just add another event listener.

So what about async?  We have had ways to do asynchronous programming in CFML for a while, but it is not very common.  In other languages though, async is a much more common way of handling activities.  The biggest thing to keep in mind with async programming is that you will not be able to get information out of the async code directly.  Async is good for tasks that you can fire and forget and you do not directly need the results in the current context.  Emit provides the ability to run this async code in a much easier and cleaner way.

> Note! treat these examples as psuedo-code.  They are not full examples you can execute, I wouldn't name things this way, I wouldn't organize things this way - these are just examples.

#Use Cases


##Application-wide event system

This example is more publish/subscribe than observer.

Imagine you have a large system with lots of actions that happen.  Users register.  Orders are created or shipped.  A user makes a payment.  The specs for this system say what needs to happen right now - but you're thinking for the future.  You want to make sure that you are prepared when the scope eventually expands and the requirements change.

So you break down all of these actions into events and you think about what kind of data goes with those events.  When a user registers, well you now have a userID, probably an email address, maybe some contact information.  When an order is created you know what is all contained in the order, who ordered it, how much the total was, etc.

In this case what I would do is create a singleton instance of emit using your favorite dependency injection framework (such as di/1) or manually if thats the way you still do things - store it in the application scope.  Then inject that instance into all of your services and send events out as they happen - even if right now you don't have any extra activities to perform.

So lets take the order example.  We have an orderService with a newOrder function that might look something like this:

```
component accessors=true {
	property emit;

	function newOrder(createdByUserID, orderContents, totalCost) {

		/*
			create the order
		*/

		emit.emit('newOrder', {orderID: orderID, createdByUserID: createdByUserID, orderContents: orderContents, totalCost: totalCost});
	}
}
```

So now, anytime an order is created that event will dispatch along with that information.  What information to include is up to you - if its not much information put it in the event - if there is a lot of information that could be included, provide the appropriate keys for the listeners to use to retrieve the information for themselves.

Now somewhere else in our application, we can register a listener that wants to know anytime that ```newOrder``` event is dispatched, because we want to send an order confirmation email.  So we can do something like this:

```
emit.on('newOrder', function(data){
	//load whatever data you need
	// send the email
}, true);
```

The orderService doesnt know anything about this email - doesnt have to.  Now the boss calls and says that he wants you to also take any products sold out of the inventory.  So you just go and register another event:


```
emit.on('newOrder', function(data){
	for (var item in data.orderContents) {
		//remove the item qty from inventory
	}
}, true);
```

Now if you have been paying attention you might notice that boolean true as the third argument to ```on()```.  This tells emit to execute these listeners asynchronously.  This means that no code is waiting on these listeners to complete - they will execute in their own thread and the newOrder() function will finish as fast as if there were no listeners at all.  But this isn't a requirement - you could execute these listeners synchronously if you would rather - and there are some benefits to doing it that way - allowing listeners to modify state for instance.  For more information see the next example.

##Allowing external code to modify state / composing services

Lets take our newOrder example again but lets say that we just expanded to some new markets that require us to charge some taxes and maybe some extra fees.  We could add code directly into newOrder to determine these taxes and fees and add them - or we could use synchronous events to allow us to hook in that logic and modify the state of our function for us.  Lets look at an example:

```
component accessors=true {
	property emit;

	function newOrder(createdByUserID, orderContents, totalCost) {

		//needs to be a struct or some other data type that is passed by reference
		var orderExtras = {
			  taxAmount = 0
			, feeAmount = 0
			, orderAmount = totalCost
			, orderState = 'TN'
			};

		emit.emit('newOrder.determineTaxes', orderExtras);

		//at this point, any synchronous listeners could have modified the orderExtras data
	}
}
```

We have to use a data type such as a struct or object that can be passed by reference for this, but we are broadcasting out an event with this data allowing listeners to modify it.  So lets say we have code like this somewhere else in our application:

```
emit.on('newOrder.determineTaxes', function(data) {
	if (data.orderState == 'TN') {
		data.taxAmount = data.orderAmount * 0.925;
		data.feeAmount = 100; //charge extra because they're from TN
		data.orderAmount += data.taxAmount;
		data.orderAmount += data.feeAmount;
		//no need to return anything
	}
}); //make sure not to pass true for async - we need this code to work synchronously
```

Other great examples for this technique would be transforming data, such as formatting phone numbers or stripping html from comments.

You also dont have to provide the listener as an anonymous function - the listener can be any function that is expecting a struct as the first argument.  So if you had a taxService like this:

```
component {
	function calculateTaxesAndFees(struct data) {
		if (data.orderState == 'TN') {
			data.taxAmount = data.orderAmount * 0.925;
			data.feeAmount = 100; //charge extra because they're from TN
			data.orderAmount += data.taxAmount;
			data.orderAmount += data.feeAmount;
			//no need to return anything
		}
	}
}
```

You could create the listener like this:

```
emit.on('newOrder.determineTaxes', taxService.calculateTaxesAndFees);
```

Which would work the same as the above example.

In any case - it is up to the person designing the source of the event to document that it a) broadcasts an event named ```newOrder.determineTaxes``` and what data is provided.

###Where to put the listeners?

So the easy, non-helpful answer is - anywhere you want.  The only requirement from emit's perspective is that the listener must be created before the event is fired.  In practice, from a code organization perspective though, it does matter.  Here are some possibilities:

1) Create listeners in onApplicationStart

So you could create a function that is called onApplicationStart, after your dependency injection has been set up, and you could wire your listeners from there.  This works better when you are using actual functions in services as your listeners, but it doesn't really matter.  This has the benefit of being a clear place to look for listeners and what is wired to what, but will probably become long and unmanageable later on.

2) Add listeners from your services themselves.

If you are using di/1, instead of injecting emit with a property, inject it using an actual setter method, such as :

```
property emit setter=false;

function setEmit(required Emit emit) {
	variables.emit = emit;

	emit.on(...)
}
```

this gives you a great place to listen for any events that this particular service is interested in.

3). Put async listeners right beside the actual functions

One of the benefits of emit providing easier async is that you don't have to separate the async code from the rest:

```
function createOrder() {

	//create the order

	emit.on('newOrder', function(){
		//create a pdf (slow)
		//send it as an attachment through email
		//I can access any data from createOrder in this function
	});

	emit.emit('newOrder', data); //other sync or async listeners can also be listening to this event

}
```

##Async Action

Have you ever written code to create a scheduled task that runs some code once and then removes itself?  Maybe it is some long running activity like generating a report or exporting some data.  All you are really trying to do is not make the user wait - it is either going to take a lot of time or might require some resource that isn't yet available.  Emit can make this much easier.


```
function someLongRunningTask () {
	/*do some setup*/
	emit.async(function(){
		/*
		long running task
		you have access here to anything you have access to from outside of the async() call.
		function arguments, variables scope, application, session, whatever.
		cannot return code directly
		maybe email results
		maybe just update the database
		maybe write to a log file
		*/
	});
}

```

You could also do this action because an event.  See TODO: put a link here to the appropriate example.




































