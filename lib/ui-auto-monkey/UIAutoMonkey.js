/////////////////////////////////////////////////////////////////////////////////////
//                         ORIGINAL Copyright
/////////////////////////////////////////////////////////////////////////////////////

// Copyright (c) 2013 Jonathan Penn (http://cocoamanifest.net/)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/////////////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////////////


"use strict";

var UIAutoMonkey = {
///////////////////////// __UIAutoMonkey Configuration Begin__  ///////////////////////////////
	config: {
		numberOfEvents: 1000,
		delayBetweenEvents: 0.05,    // In seconds
        result_detail_event_num: 20,

		// Events are triggered based on the relative weights here. The event
		// with this highest number gets triggered the most.
		//
		// If you want to add your own "events", check out the event method
		// definitions below.
		eventWeights: {
			tap: 500,
			drag: 100,
			flick: 100,
			orientation: 1,
			clickVolumeUp: 1,
			clickVolumeDown: 1,
			lock: 3,
			pinchClose: 50,
			pinchOpen: 50,
			shake: 1,
			deactivate: 3
		},

		// Probability that touch events will have these different properties
		touchProbability: {
			multipleTaps: 0.05,
			multipleTouches: 0.05,
			longPress: 0.05
		},

		// Uncomment the following to restrict events to a rectangluar area of
		// the screen
		/*
		frame: {
			origin: {x: 0, y: 0},
			size: {width: 100, height: 50}
		}
		*/
	},
///////////////////////// __UIAutoMonkey Configuration End__  ///////////////////////////////

	// --- --- --- ---
	// Event Methods
	//
	// Any event probability in the hash above corresponds to a related event
	// method below. So, a "tap" probability will trigger a "tapEvent" method.
	//
	// If you want to add your own events, just add a probability to the hash
	// above and then add a corresponding method below. Boom!
	//
	// Each event method can call any other method on this UIAutoMonkey object.
	// All the methods at the end are helpers at your disposal and feel free to
	// add your own.

	tapEvent: function() {
        var p1 = { x: this.randomX(), y: this.randomY() };
		this.target().tapWithOptions(p1,
			{
				tapCount: this.randomTapCount(),
				touchCount: this.randomTouchCount(),
				duration: this.randomTapDuration()
			}
		);
	},

	dragEvent: function() {
        var p1 = { x: this.randomX(), y: this.randomY() };
        var p2 = { x: this.randomX(), y: this.randomY() };
		this.target().dragFromToForDuration(p1, p2, 0.5);
	},

	flickEvent: function() {
        var p1 = { x: this.randomX(), y: this.randomY() };
        var p2 = { x: this.randomX(), y: this.randomY() };
		this.target().flickFromTo(p1, p2);
	},

	orientationEvent: function() {
		var orientations = [
			UIA_DEVICE_ORIENTATION_PORTRAIT,
			UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN,
			UIA_DEVICE_ORIENTATION_LANDSCAPELEFT,
			UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT
		];

		var i = Math.floor(Math.random() * 10) % orientations.length;
		var newOrientation = orientations[i];
		this.target().setDeviceOrientation(newOrientation);
		this.delay(0.9);
	},

	clickVolumeUpEvent: function() {
		this.target().clickVolumeUp();
	},

	clickVolumeDownEvent: function() {
		this.target().clickVolumeDown();
	},

	lockEvent: function() {
		this.target().lockForDuration(Math.random() * 3);
	},

	pinchCloseEvent: function () {
        var p1 = { x: this.randomX(), y: this.randomY() };
        var p2 = { x: this.randomX(), y: this.randomY() };
		this.target().pinchCloseFromToForDuration(p1, p2, 0.5);
	},

	pinchOpenEvent: function () {
        var p1 = { x: this.randomX(), y: this.randomY() };
        var p2 = { x: this.randomX(), y: this.randomY() };
		this.target().pinchOpenFromToForDuration(p1, p2, 0.5);
	},

	shakeEvent: function() {
		this.target().shake();
	},
	
	deactivateEvent: function() {
		this.target().deactivateAppForDuration(5 + Math.random() * 10);
	},

	// --- --- --- ---
	// Helper methods
	//

    results_path: function() {
        var host = this.target().host();
        var results = host.performTaskWithPathArgumentsTimeout("/bin/bash", ["-c", "echo -n $UIARESULTSPATH"], 5);
        var ret = results.stdout;
        UIALogger.logDebug("results_path: '" + ret+"'");
        return ret;
    },

    deleteImage: function(dir, from, to) {
        var host = this.target().host();
        var files = [];
        for (var i=from; i < to; i++) {
            files.push(dir + "/screen-"+i + ".png");
            // files.push(dir + "/action-"+i + ".png");
        }
        host.performTaskWithPathArgumentsTimeout("/bin/rm", files, 5);
    },

	RELEASE_THE_MONKEY: function() {
		// Called at the bottom of this ui-auto-monkey to, you know...
		//
		// RELEASE THE MONKEY!
        var target = this.target();
		var initBundleID = target.frontMostApp().bundleID();
        var results_path = this.results_path();
        var result_num = this.config.result_detail_event_num;

		for(var i = 0; i < this.config.numberOfEvents; i++) {
            // Delete old images
            if (i % 10 == 0 && i > result_num) {
                this.deleteImage(results_path, i-result_num-10, i-result_num);
            }
            // Capture Screen Image
            target.captureScreenWithName("screen-" + i);
            // if another application become frontMost, exit.
            var bundleID = target.frontMostApp().bundleID();
            if (bundleID != initBundleID) {
                UIALogger.logDebug("************************ Different Application **************: " + bundleID);
                break;
            }

            // Send Random Event
            this.triggerRandomEvent();

            // Wait
			this.delay();
		}
	},

	triggerRandomEvent: function() {
		var name = this.chooseEventName();
		// Find the event method based on the name of the event
		var event = this[name + "Event"];
		return event.apply(this);
	},

	target: function() {
		// Return the local target.
		return UIATarget.localTarget();
	},

	delay: function(seconds) {
		// Delay the target by `seconds` (can be a fraction)
		// Defaults to setting in configuration
		seconds = seconds || this.config.delayBetweenEvents;
		this.target().delay(seconds);
	},

	chooseEventName: function() {
		// Randomly chooses an event name from the `eventsWeight` dictionary
		// based on the given weights.
		var calculatedEventWeights = [];
		var totalWeight = 0;
		var events = this.config.eventWeights;
		for (var event in events) {
			if (events.hasOwnProperty(event)) {
				calculatedEventWeights.push({
					weight: events[event]+totalWeight,
					event: event
				});
				totalWeight += events[event];
			}
		}

		var chosenWeight = Math.random() * 1000 % totalWeight;

		for (var i = 0; i < calculatedEventWeights.length; i++) {
			if (chosenWeight < calculatedEventWeights[i].weight) {
				return calculatedEventWeights[i].event;
			}
		}

		throw "No even was chosen!";
	},

	screenWidth: function() {
		// Need to adjust by one to stay within rectangle
		return this.target().rect().size.width - 1;
	},

	screenHeight: function() {
		// Need to adjust by one to stay within rectangle
		return this.target().rect().size.height - 1;
	},

	randomX: function() {
		var min, max;

		if (this.config.frame){
			// Limits coordinates to given frame if set in config
			min = this.config.frame.origin.x;
			max = this.config.frame.size.width + min;
		} else {
			// Returns a random X coordinate within the screen rectangle
			min = 0;
			max = this.screenWidth();
		}

		return Math.floor(Math.random() * (max - min) + min) + 1;
	},

	randomY: function() {
		var min, max;

		if (this.config.frame){
			// Limits coordinates to given frame if set in config
			min = this.config.frame.origin.y;
			max = this.config.frame.size.height + min;
		} else {
			// Returns a random Y coordinate within the screen rectangle
			min = 0;
			max = this.screenHeight();
		}

		return Math.floor(Math.random() * (max - min) + min) + 1;
	},

	randomTapCount: function() {
		// Calculates a tap count for tap events based on touch probabilities
		if (this.config.touchProbability.multipleTaps > Math.random()) {
			return Math.floor(Math.random() * 10) % 3 + 1;
		}
		else return 1;
	},

	randomTouchCount: function() {
		// Calculates a touch count for tap events based on touch probabilities
		if (this.config.touchProbability.multipleTouches > Math.random()) {
			return Math.floor(Math.random() * 10) % 3 + 1;
		}
		else return 1;
	},

	randomTapDuration: function() {
		// Calculates whether or not a tap should be a long press based on
		// touch probabilities
		if (this.config.touchProbability.longPress > Math.random()) {
			return 0.5;
		}
		else return 0;
	},

	randomRadians: function() {
		// Returns a random radian value
		return Math.random() * 10 % (3.14159 * 2);
	}
};

UIAutoMonkey.RELEASE_THE_MONKEY();

/* Instruments uses 4-wide tab stops. */
/* vim: set tabstop=4 shiftwidth=4 softtabstop=4 copyindent noexpandtab: */
