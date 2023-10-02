# webapi.rb
require 'sinatra'
require 'json'
require 'sqlite3'

def make_query(query, *params)
  db = SQLite3::Database.open 'foodndishes.db'
  db.results_as_hash = true

  array = []

  stm = db.prepare(query)
  stm.bind_param(params)

  result_set = stm.execute

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

get '/:ingredient' do
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
get '/veganveg' do
  value = 1
  result = make_query("SELECT * FROM dishes WHERE vegetarian_or_vegan =?;", value)
  return result.to_json
end

#will fetch dishes based on it being dishes name
get '/dish/:name' do
  name = params[:name].capitalize()
  name ||= name.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes WHERE name = '#{name}';")
  return result.to_json
end

post '/disheswith/:ingredient' do
  ingredient = JSON.parse(request.body.read)
  ingredients[ingredient['name'].downcase.to_sym] = ingredient

  url = "http://localhost:4567/users/#{ingredient['name']}"
  response.headers['Location'] = url   
  status 201
end

# post '' do
#   ingredient = JSON.parse(request.body.read)
#   # ingredient = params[:ingredient]
#   ingredients[ingredient['name'].downcase.to_sym] = ingredient

#   url = "http://localhost:4567/users/#{ingredient['name']}"
#   response.headers['Location'] = url   
#   status 201
# end
