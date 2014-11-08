emit Use Cases
==============

##Project Goals

The two primary things that emit provides is:

1). An implementation of the observer pattern for event driven programming in CFML
2). Easy implementation of asynchronous programming

In the following sections I will attempt to explain these in more detail and to give some concrete examples of where these things can be useful.

##Concepts

If you have ever programmed in javascript or actionscript, you have likely done some event driven programming.  It is much more common in these languages, because it is a very useful concept for dealing with UI based events.  Any time you have use jquery's ```on()``` or just straight ```addEventListener``` you were doing event driven programming.  At its core, the idea is that something will broadcast out an event (and optionally associated data) and if anything else cares to know when that event occurs, they can register their interest and provide actions to perform in that case.  I want to click a button, and I want this to happen.

The first great part of event driven programming is that it provides an extension point that the original author didnt have to consider at the time the source was being designed or written, and it gives you a way to tie things together in a very loosely coupled way.  In javascript, the button does not require any knowledge of what my code intends to do when a button is clicked, it just has to broadcast out the information and it is up to the listener to do with that information what it will.  And if no-one is listening, that is okay too, nothing happens.

The second benefit is that many listeners can be added to the same event without changing the source of the event.  So today you know that you need to do y when x happens.  Later on the requirements change and you need to do z as well.  Now instead of changing the source, you just add another event listener.

So what about async?  We have had ways to do asynchronous programming in CFML for a while, but it is not very common.  In other languages though, async is a much more common way of handling activities.  The biggest thing to keep in mind with async programming is that you will not be able to get information out of the async code directly.  Async is good for tasks that you can fire and forget and you do not directly need the results in the current context.  Emit provides the ability to run this async code in a much easier and cleaner way.

#Use Cases

##1. Async Action

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