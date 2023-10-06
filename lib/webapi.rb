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

#------------------------------------------------------------------------------------------------------------------------------------------------
#GET METHODS
#------------------------------------------------------------------------------------------------------------------------------------------------
# introductory part of website
get '/' do
  'This is sinatra web api response 😎'
end

#search
get '/search/:ingredient' do
  ingredient = params[:ingredient]
  ingredient = ingredient.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes AS d JOIN ingredients_in_dish USING(dishes_id) JOIN ingredients AS i USING(ingredients_id) WHERE i.name =?;", ingredient)
  return result.to_json
end 

#will fetch dishes based on ingredients 
get '/disheswith/:ingredient' do
  ingredient = params[:ingredient].capitalize()
  ingredient = ingredient.split.map(&:capitalize).join(' ')
  result = make_query("SELECT d.name FROM dishes AS d JOIN ingredients_in_dish USING(dishes_id) JOIN ingredients AS i USING(ingredients_id) WHERE i.name =?;", ingredient)
  return result.to_json
end

#will fetch dishes based on cuisine 
get '/dishesin/:cuisine' do
  cuisine = params[:cuisine]
  cuisine = cuisine.split.map(&:capitalize).join(' ')
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
get '/dishes/:name' do
  name = params[:name].capitalize()
  name = name.split.map(&:capitalize).join(' ')
  result = make_query("SELECT * FROM dishes WHERE name = '#{name}';")
  return result.to_json
end

#------------------------------------------------------------------------------------------------------------------------------------------------
#POST METHOD
#------------------------------------------------------------------------------------------------------------------------------------------------
# #curl -X POST http://localhost:4567/dishes -d '{--hashvals--}'
post '/dishes' do
  db = SQLite3::Database.open 'foodndishes.db'

  request_body = JSON.parse(request.body.read)

  begin
    name = request_body.fetch('name')
    country = request_body.fetch('country')
    taste = request_body.fetch('taste')
    meal = request_body.fetch('meal')
    vegetarian_or_vegan = request_body.fetch('vegetarian_or_vegan')
    cuisines_id = request_body.fetch('cuisines_id')

    if !name.is_a?(String) || !country.is_a?(String) || !taste.is_a?(String) || !meal.is_a?(String) || !vegetarian_or_vegan.is_a?(Integer) || !cuisines_id.is_a?(Integer) 
      raise TypeError
    end

  insert_stm = db.prepare("INSERT INTO dishes (name, country, taste, meal, vegetarian_or_vegan, cuisines_id) VALUES (?, ?, ?, ?, ?, ?)")
  insert_stm.execute(name, country, taste, meal, vegetarian_or_vegan, cuisines_id)
  insert_stm.close

  status 201
  db.close
  rescue KeyError
    p "The user did not provide inputs for all fields"
    status 400
    "invalid input"
  rescue TypeError
    p "User provided invalid input"
    status 400
    "invalid input!!"
  end 
end

#------------------------------------------------------------------------------------------------------------------------------------------------
#PUT METHOD
#------------------------------------------------------------------------------------------------------------------------------------------------
# curl -X PUT http://localhost:4567/dishes/40 -d '{--hashvals--}'
put '/dishes/:id' do
  db = SQLite3::Database.open 'foodndishes.db'

  id = params[:id]
  request_body = JSON.parse(request.body.read)

  begin
    name = request_body.fetch('name')
    country = request_body.fetch('country')
    taste = request_body.fetch('taste')
    meal = request_body.fetch('meal')
    vegetarian_or_vegan = request_body.fetch('vegetarian_or_vegan')
    cuisines_id = request_body.fetch('cuisines_id')
    
    if !name.is_a?(String) || !country.is_a?(String) || !taste.is_a?(String) || !meal.is_a?(String) || !vegetarian_or_vegan.is_a?(Integer) || !cuisines_id.is_a?(Integer) 
      raise TypeError
    end

    db.execute(
    'UPDATE dishes SET name = ?, country = ?, taste = ?, meal = ?, vegetarian_or_vegan = ?, cuisines_id = ? WHERE dishes_id = ?',
    name, country, taste, meal, vegetarian_or_vegan, cuisines_id, id
    )

  status 200
  db.close
  rescue KeyError
    p "The user did not provide inputs for all fields"
    status 400
    "invalid input"
  rescue TypeError
    p "User provided invalid input"
    status 400
    "invalid input!!"
  end 
end 

#------------------------------------------------------------------------------------------------------------------------------------------------
#PATCH METHOD
#------------------------------------------------------------------------------------------------------------------------------------------------
#curl -X PATCH http://localhost:4567/dishes/47 -d
def build_update_sql_and_values(update_sql, values, field_name, field_value)
  if field_value
    update_sql << "#{field_name} = ?"
    values << field_value
  end
end

patch '/dishes/:id' do
  begin 
  db = SQLite3::Database.open 'foodndishes.db'

  id = params[:id]
  request_body = JSON.parse(request.body.read)

  name = request_body["name"]
  country = request_body["country"]
  taste = request_body["taste"]
  meal = request_body["meal"]
  vegetarian_or_vegan = request_body["vegetarian_or_vegan"]
  cuisines_id = request_body["cuisines_id"]

  update_sql = []
  values = []

  field_names = ['name', 'country', 'taste', 'meal', 'vegetarian_or_vegan', 'cuisines_id']

  field_names.each do |fieldname|
      build_update_sql_and_values(update_sql, values, fieldname, request_body[fieldname])
    end

  if !update_sql.empty?
    update_sql_str = update_sql.join(', ')
    db.execute("UPDATE dishes SET #{update_sql_str} WHERE dishes_id = ?", values + [id])
  end

  status 200
  rescue JSON::ParserError => e
    status 400 # Bad Request
    body "JSON parsing error: #{e.message}"
  rescue SQLite3::Exception => e
    status 500 # Internal Server Error
    body "Database error: #{e.message}"
  ensure
    db.close if db
  end
end

#------------------------------------------------------------------------------------------------------------------------------------------------
#DELETE METHOD
#------------------------------------------------------------------------------------------------------------------------------------------------
#curl -X DELETE -v http://localhost:4567/dishes/47 
delete '/dishes/:id' do
  begin 
    db = SQLite3::Database.open 'foodndishes.db'
    id = params[:id]

    db.execute("DELETE FROM dishes WHERE dishes_id = ?;", id)

    status 204

  rescue SQLite3::Exception => e
    status 500 # Internal Server Error
    body "An error occurred: #{e.message}" # Return the error message as the response body

  ensure
    db.close
  end
end 