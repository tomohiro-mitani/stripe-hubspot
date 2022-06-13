# Stripe and Hubspot Integration

This simple demo was  built to show quote to cash automation by using Stripe and Hubspot. Products in Stripe are integrated with that of Hubspot by using Integorate. A scenario in Integorate listens to the Stripe events. Whenever a product is created in Stripe, Integorate will create the equivalent product in Hubspot.

## Overview

This demo has the following features, Stripe products, and Hubspot integrations:

### Requirements

* You'll need a Stripe account. [Sign up for free](https://dashboard.stripe.com/register) before running the application.
* Ruby 2.6.3

### Getting Started

Sync products between Stripe and HubSpot through using Integromat.

Create a subscription product in Stripe and let Integromat sync the product in HubSpot.

Create a HubSpot deal with products as line items.

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

Go to [http://localhost:4567/?deal=DEAL_ID](http://localhost:4567/?deal=DEAL_ID) in your browser to start using the demo.


