# webapi.rb
require 'sinatra'
require 'json'
require 'sqlite3'

#method that simplifies process of getting data based on params in websites URL
def make_query(query, *params)
  db = SQLite3::Database.open 'foodndishes.db'
  db.results_as_hash = true

  array = []

  stm = db.prepare(query)
  params.each_with_index do |param, index|
    stm.bind_param(index + 1, param)
  end

  result_set = stm.execute(query)

  while (row = result_set.next) do
      array.push(row)
  end
  
  array 
  rescue SQLite3::Exception => e 
  
    puts "Exception occurred"
    puts e
    []
end 

# introductory part of website
get '/' do
  'This is sinatra web api response 😎'
end

#search
get '/search/:ingredient' do
  ingredient = params[:ingredient]
  ingredient ||= ingredient.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes AS d JOIN ingredients_in_dish USING(dishes_id) JOIN ingredients AS i USING(ingredients_id) WHERE i.name =?;", ingredient)
  return result.to_json
end 

#will fetch dishes based on ingredients 
get '/disheswith/:ingredient' do
  ingredient = params[:ingredient].capitalize()
  ingredient ||= ingredient.split.map(&:capitalize).join(' ')
  result = make_query("SELECT d.name FROM dishes AS d JOIN ingredients_in_dish USING(dishes_id) JOIN ingredients AS i USING(ingredients_id) WHERE i.name =?;", ingredient)
  return result.to_json
end

#will fetch dishes based on cuisine 
get '/dishesin/:cuisine' do
  cuisine = params[:cuisine]
  cuisine ||= cuisine.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes AS d JOIN cuisines AS c USING(cuisines_id) WHERE c.name =?;", cuisine)
  return result.to_json
end

#will fetch dishes based on it being  vegetarian or vegans 
#doesnt work with value without params for some reason -- wth
#using normal seperate format ----
get '/veganveg' do
  db = SQLite3::Database.open 'foodndishes.db'
  db.results_as_hash = true

  array = []
  
  result_set = db.query("SELECT * FROM dishes WHERE vegetarian_or_vegan =1;")

  while (row = result_set.next) do
      array.push(row)
  end

  return array.to_json

  rescue SQLite3::Exception => e 
  
    puts "Exception occurred"
    puts e
    []
end

#will fetch dishes based on it being dishes name
get '/dish/:name' do
  name = params[:name].capitalize()
  name ||= name.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes WHERE name = '#{name}';")
  return result.to_json
end

# post '/disheswith/:ingredient' do
#   ingredient = JSON.parse(request.body.read)
#   ingredients[ingredient['name'].downcase.to_sym] = ingredient

#   url = "http://localhost:4567/users/#{ingredient['name']}"
#   response.headers['Location'] = url   
#   status 201
# end

post '/veganveg' do
  ingredient = JSON.parse(request.body.read)
  # ingredient = params[:ingredient]
  ingredients[ingredient['name'].downcase.to_sym] = ingredient

  url = "http://localhost:4567/users/#{ingredient['name']}"
  response.headers['Location'] = url   
  status 201
end
