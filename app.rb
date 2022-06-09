require 'dotenv/load'
require 'sinatra'
require 'sinatra/reloader'
require 'stripe'
require 'money'
require 'byebug'
require 'securerandom'

require './lib/lib'
require './lib/setup'

Stripe.api_key = ENV["SK_KEY"]

require 'uri'
require 'net/http'
require 'openssl'
require 'hubspot-api-client'


def deal_to_line_items(deal)
  begin
    hapi_api_key = ENV["HS_KEY"]
    url = URI("https://api.hubapi.com/crm/v3/objects/deals/" + deal + "/associations/line_items?hapikey=" + hapi_api_key)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["accept"] = 'application/json'
    
    response = http.request(request)

    puts response.read_body

    array_object = JSON.parse(response.read_body)["results"]

    line_items_array = []
    array_object.each do |l_i|
      line_items_array << l_i["id"]
    end
  rescue
    puts "error"
  end
  line_items_array
end

def get_stripe_price_id_array(line_items_array)
  # Get line item id from the deal
  require 'hubspot-api-client'
  hapi_api_key = ENV["HS_KEY"]

  Hubspot.configure do |config|
    config.api_key['hapikey'] = hapi_api_key
  end
    
  stripe_price_id_array = []
  line_items_array.each do |line_item_id|
    begin
      api_response = Hubspot::Crm::LineItems::BasicApi.new.get_by_id(line_item_id, archived: false, auth_names: "hapikey")
      product_id = api_response.properties["hs_product_id"]
    rescue Hubspot::Crm::LineItems::ApiError => e
      error_message = JSON.parse(e.response_body)['message']
      puts error_message
    end
    begin
      url = URI("https://api.hubapi.com/crm-objects/v1/objects/products/" + product_id + "?hapikey=" + hapi_api_key + "&properties=stripe_price_id")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url)
      request["accept"] = 'application/json'
      response = http.request(request)
      stripe_price_id =  JSON.parse(response.read_body)["properties"]["stripe_price_id"]["versions"][0]["value"]
      stripe_price_id_array << stripe_price_id

    rescue Hubspot::Crm::Products::ApiError => e
      error_message = JSON.parse(e.response_body)['message']
      puts error_message
    end
  end
  stripe_price_id_array
end

def get_total_amount(stripe_price_id_array)
  unit_amount_array = []
  total_amount = 0
  stripe_price_id_array.each do |stripe_price_id|
    item_amount = Stripe::Price.retrieve(
      stripe_price_id,
    ).unit_amount
    unit_amount_array << item_amount/100
    unless item_amount.nil?
      total_amount += item_amount
    end
  end
  total_amount = total_amount / 100
  [unit_amount_array, total_amount]
end

def get_products_amount_array(stripe_price_id_array, unit_amount_array)
  products_id_array = []
  stripe_price_id_array.each do |stripe_price_id|
    product_id = Stripe::Price.retrieve(
      stripe_price_id,
    ).product
    products_id_array << product_id
  end

  products_amount_array = []
  index = 0
  products_id_array.each do |product_id, i|
    products_amount_array << [Stripe::Product.retrieve(
      product_id,
    ).name, unit_amount_array[index]]
    index += 1
  end
  products_amount_array
end

get '/' do
  
  @deal = params[:deal]
  line_items_array = deal_to_line_items(@deal)
  @stripe_price_id_array = get_stripe_price_id_array(line_items_array)
  result_array = get_total_amount(@stripe_price_id_array)
  unit_amount_array = result_array[0]
  @total_amount = result_array[1]
  @products_amount_array = get_products_amount_array(@stripe_price_id_array, unit_amount_array)

  erb :index, locals: { type: params[:type] }
end

get '/checkout' do
  hapi_api_key = ENV["HS_KEY"]
  @deal = params[:deal]
  url = URI("https://api.hubapi.com/crm/v3/objects/deals/" + @deal + "/associations/contacts?hapikey=" + hapi_api_key)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  request = Net::HTTP::Get.new(url)
  request["accept"] = 'application/json'
  
  response = http.request(request)
  puts response.read_body
  contact_id = JSON.parse(response.read_body)["results"][0]["id"] 

  url = URI("https://api.hubapi.com/crm/v3/objects/deals/" + @deal + "/associations/companies?hapikey=" + hapi_api_key)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url)
  request["accept"] = 'application/json'

  response = http.request(request)
  puts response.read_body
  company_id = JSON.parse(response.read_body)["results"][0]["id"]

  begin    
    api_response = Hubspot::Crm::Contacts::BasicApi.new.get_by_id(contact_id, archived: false, auth_names: "hapikey")
    company_api_response = Hubspot::Crm::Companies::BasicApi.new.get_by_id(company_id, archived: false, auth_names: "hapikey")
    @first_name = api_response.properties["firstname"]
    @last_name = api_response.properties["lastname"]
    @email = api_response.properties["email"]
    @company_name = company_api_response.properties["name"]
  rescue Hubspot::Crm::Contacts::ApiError => e
    error_message = JSON.parse(e.response_body)['message']
    puts error_message
  end

  line_items_array = deal_to_line_items(@deal)
  stripe_price_id_array = get_stripe_price_id_array(line_items_array)
  result_array = get_total_amount(stripe_price_id_array)
  @total_amount = result_array[1]

  erb :checkout, locals: { type: params[:type] }
end

post '/subscribe' do
  #get price_ids from hubspot

  deal = params[:deal]

  line_items_array = deal_to_line_items(deal)
  stripe_price_id_array = get_stripe_price_id_array(line_items_array)

  stripe_price_id_array_with_hash = []
  stripe_price_id_array.each do |price_id|
    stripe_price_id_array_with_hash << { price: price_id }
  end

  begin
    # create customer for email with params[:pm_id]
    customer = Stripe::Customer.create({
      email: params[:email],
      name: params[:company_name],
      payment_method: params[:payment_method_id],
      metadata: {contact_name: [params[:last_name], params[:first_name]].join(" ")},
    })

   subscription = Stripe::Subscription.create({
      customer: customer.id,
      default_payment_method: params[:payment_method_id],
      items: stripe_price_id_array_with_hash,
   })

    redirect "/success?subscription=#{subscription.id}"
  rescue Stripe::StripeError => e
    redirect "/error?error=#{e.error.message}"
  end
end

post '/create-customer-portal-session' do
  session = Stripe::BillingPortal::Session.create({
    customer: params[:customer],
    return_url: "#{ENV["HOST"]}/success?subscription=#{params[:subscription]}"
  })

  redirect session.url
end

get '/success' do
  @subscription = Stripe::Subscription.retrieve({
    id: params[:subscription], 
    expand: ['customer']
  })

  puts @subscription
  puts @subscription.customer
  
  erb :success
end

get '/error' do
  status 500
  @error = params[:error]
  erb :error
end

