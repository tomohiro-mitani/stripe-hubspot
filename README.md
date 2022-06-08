# Stripe and Hubspot Integration

This simple demo was  built to show quote to cash automation by using Stripe and Hubspot. Products in Stripe are integrated with that of Hubspot by using Integorate. A scenario in Integorate listens to the Stripe events. Whenever a product is created in Stripe, Integorate will create the equivalent product in Hubspot.


<img width="2069" alt="Screen Shot 2021-10-21 at 10 59 53 AM" src="https://git.corp.stripe.com/storage/user/4247/files/0d1d9580-325e-11ec-80bb-38f3c8e10ff3">

## Overview

This demo has the following features, Stripe products, and Hubspot integrations:

## Running locally

If you want to run this demo locally against a different Stripe account, follow the instructions below:

### Requirements

* You'll need a Stripe account. [Sign up for free](https://dashboard.stripe.com/register) before running the application.
* Ruby 2.6.3

### Getting Started

Clone the repo and install dependencies:

```
$ git clone https://git.corp.stripe.com/stripe-internal/solutions-demos
$ cd simple-monthly-billing
$ bundle
```

Copy the .env.template file. You'll need to fill out the Publishable and Secret key details from your [Stripe account](https://dashboard.stripe.com/account/apikeys)

```
$ cp .env.template .env
```

Run the app!
```
$ bundle exec ruby app.rb
```

Go to [http://localhost:4567](http://localhost:4567) in your browser to start using the demo.

## Resetting Data
If you'd like to wipe the slate clean and start with a fresh environment, you can [wipe all test data](https://dashboard.stripe.com/account/data) from your Stripe account. This demo runs purely on top of the Stripe API with no local database so wiping the Stripe account resets the entire application.


## Credits
* Code: [Tomohiro Mitani, David Santoso]
* Stock photos provided by [Unsplash](https://unsplash.com/)
