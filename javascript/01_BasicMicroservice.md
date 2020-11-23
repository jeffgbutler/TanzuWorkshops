# Basic Microservice with JavaScript, Express, and Node.js

This workshop will guide you through creating a simple microservice using the Express framework (https://expressjs.com/).
We will create a JavaScript based microservice that runs in Node.js - and can easily be containerized for Docker or Kubernetes.

## Pre-Requisites

You will need Node.js installed on your workstation to run the code in this workshop. Node.js is updated frequently and it is
likely you will want multiple versions of Node.js installed at one time or another. For this reason, we recommend that you install
a "node version manager" (NVM) that will allow you to easily install different Node.js versions and switch between them.

For *nix, macOS, and Windows WSL use NVM from here: https://github.com/nvm-sh/nvm

For Windows (not WSL) use nvm-windows from here: https://github.com/coreybutler/nvm-windows

If you are not concerned about different versions of Node.js, you can simply install the latest version from https://nodejs.org/

It will also help to have a good IDE that supports JavaScript and Node.js development. We prefer VisualStudio Code which
can be installed from https://visualstudio.microsoft.com/. VisualStudio Code includes support for Node.js development out of the box.

## Create the Basic Application

We're going to use the Express Generator to bootstrap an application.

1. Create a directory called `nodejs_payment_calculator`
1. Open a command/terminal window in that directory
1. Enter the command `npx express-generator --no-view --git` - this will create a basic Node.js application that is almost ready to run
1. Enter the command `npm install` - this will download all the dependencies for the application
1. Enter the command `npm install cors` - this will add support for cross origin resource sharing
1. Enter the command `npm start` - this will start the application and you can see the homepage at http://localhost:3000
1. Stop the application by entering `control-c` in the terminal window


## Create a Payment Service

1. Create a directory `services` in the `../nodejs-payment-calculator` directory
1. Create a file in the `services` directory called `paymentCalculator.js` and set its contents to the following:

   ```javascript
   function toMoney(amount) {
       return Math.round(amount * 100) / 100;
   }

   function calculateWithoutInterest(amount, years) {
       let payment = amount / (years * 12.0);
       return toMoney(payment);
   }

   function calculateWithInterest(amount, rate, years) {
       let monthlyRate = rate / 100.0 / 12.0;
       let numberOfPayments = years * 12;
       let payment = (monthlyRate * amount) / (1.0 - Math.pow(1.0 + monthlyRate, -numberOfPayments));
       return toMoney(payment);
   }

   function calculatePayment(amount, rate, years) {
       if (rate == 0) {
           return calculateWithoutInterest(amount, years);
       } else {
           return calculateWithInterest(amount, rate, years);
       }
   }

   module.exports = calculatePayment;
   ```

   This exposes a function that will calculate a loan payment.

## Create a Hit Counter Service

1. Create a file in the `services` directory called `hitCounter.js` and set its contents to the following:

   ```javascript
   let hitCount = 0;

   function reset () {
       hitCount = 0;
   }

   function increment () {
       return ++hitCount;
   }

   module.exports = {reset, increment};
   ```
   This exposes a simple memory based hit counter that can be incremented or reset.

## Create a Crash Service

1. Create a file in the `services` directory called `crasher.js` and set its contents to the following:

   ```javascript
   function crashIt() {
       setTimeout(function () { process.exit(); }, 2000);
   }

   module.exports = crashIt;
   ```

   This exposes a function that will stop Node.js 2 seconds after it is called (effectively crashing the application).

## Create a Route for the Payment Service

1. Create a file in the `routes` directory called `payment.js` and set its contents to the following:

   ```javascript
   var calculatePayment = require('../services/paymentCalculator');
   var hitCounter = require('../services/hitCounter');
   var instance = process.env.MY_POD_NAME || 'local';

   var express = require('express');
   var router = express.Router();

   router.get('/', function (req, res, next) {
       let amount = parseFloat(req.query.amount);
       let rate = parseFloat(req.query.rate);
       let years = parseInt(req.query.years);

       let answer = {
           amount: amount,
           rate: rate,
           years: years,
           payment: calculatePayment(amount, rate, years),
           instance: instance,
           count: hitCounter.increment()
       };

       // force the browser to open a new connection
       // DO NOT do this in production - this is only to
       // demonstrate load balancing on K8S
       res.set("Connection", "close");

       res.send(answer);
   });

   module.exports = router;
   ```

   This creates a REST endpoint that accepts three query string parameters `amount`, `rate`, and `years`. It will
   calculate a loan payment based on those three values and return a JSON object with the results. This code does
   no error checking so it is a bit fragile, but it is good enough for our purposes.


## Create a Route to Reset the Hit Count

1. Create a file in the `routes` directory called `resetCount.js` and set its contents to the following:

   ```javascript
   var hitCounter = require('../services/hitCounter');

   var express = require('express');
   var router = express.Router();

   router.get('/', function (req, res, next) {
       hitCounter.reset();

       res.send("OK");
   });

   module.exports = router;
   ```

   This creates a REST endpoint that will reset the hit counter.

## Create a REST Controller to Crash the Application

This is needed to demonstrate Kubernetes' self-healing capabilities.

1. Create a file in the `routes` directory called `crash.js` and set its contents to the following:

   ```javascript
   var crashIt = require('../services/crasher');

   var express = require('express');
   var router = express.Router();

   router.get('/', function (req, res, next) {
       crashIt();

       res.send("OK");
   });

   module.exports = router;
   ```

   This creates a REST endpoint that will crash the application 2 seconds after it is called.

## Wire Up the Routes

1. Open the file `app.js` and make the following changes:
1. Add the following statements after the line that requires the index router:

   ```javascript
   var paymentRouter = require('./routes/payment');
   var resetCountRouter = require('./routes/resetCount');
   var crashRouter = require('./routes/crash');
   ```

1. Add the following statement before the line that uses the index router:

   ```javascript
   app.use(cors());
   ```
   This will allow all cross origin requests.

1. Add the following statements after the line that uses the index router:

   ```javascript
   app.use('/payment', paymentRouter);
   app.use('/resetCount', resetCountRouter);
   app.use('/crash', crashRouter);
   ```

## Testing

1. Start the application by entering the command `npm start` in the terminal/command window
1. You can test the basic function by entering `curl "http://localhost:3000/payment?amount=100000&rate=3.5&years=30"`
1. You can also test the basic function by opening a browser and navigating to `http://localhost:3000/payment?amount=100000&rate=3.5&years=30`
1. You can also generate random traffic to the application with a traffic simulator...
   - Open `https://jeffgbutler.github.io/payment-calculator-client/`
   - Enter a base URL of `http://localhost:3000`
   - Press the "Start" Button
   - What happens when you press the "Reset Count" button?
   - What happens when you press the "Crash It!" button?

