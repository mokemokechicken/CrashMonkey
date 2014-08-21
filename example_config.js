{
        numberOfEvents: 1000,
        delayBetweenEvents: 0.05,    // In seconds

        // If the following line is uncommented, then screenshots are taken
        // every "n" seconds.
        //screenshotInterval: 5,

        // Events are triggered based on the relative weights here. The event
        // with this highest number gets triggered the most.
        //
        // If you want to add your own "events", check out the event method
        // definitions below.
        eventWeights: {
            tap: 500,
            drag: 1,
            flick: 1,
            orientation: 1,
            clickVolumeUp: 1,
            clickVolumeDown: 1,
            lock: 1,
            pinchClose: 10,
            pinchOpen: 10,
            shake: 1
        },

        // Probability that touch events will have these different properties
        touchProbability: {
            multipleTaps: 0.05,
            multipleTouches: 0.05,
            longPress: 0.05
        }

        // Uncomment the following to restrict events to a rectangluar area of
        // the screen
        /*
        frame: {
            origin: {x: 0, y: 0},
            size: {width: 100, height: 50}
        }
        */

    }