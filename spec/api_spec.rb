require_relative '../lib/webapi'
require 'rspec'
require 'rack/test'
require 'json'

describe "Saanvi's food app" do 
    include Rack::Test::Methods

    def app
        Sinatra::Application
    end

    describe "GET /disheswith/ingredient" do
        it "returns correct data and http code" do
            get "disheswith/potato"

            expect(last_response.body).to eq('[{"name":"Vegetable Pulao"},{"name":"Pav Bhaji"},{"name":"French Fries"}]')
            expect(last_response).to be_ok
        end
    end

    describe "POST /dishes" do
        it "posts correct data and http code" do
            # post '/create', params = { key1: 'value1', key2: 'value2' }
            post "/dishes", JSON.generate({                    
            name: "Chills",
            country: "hey",
            taste: "eh",
            meal: "brek",
            vegetarian_or_vegan: 1,
            cuisines_id: 12
        })

        expect(last_response.status).to eq 201
        end
    end

    describe "PUT /dishes/id" do
        it "puts correct data and http code" do
            put "/dishes/28", JSON.generate({                    
      name: "Chills",
      country: "hey",
      taste: "eh",
      meal: "brek",
      vegetarian_or_vegan: 1,
      cuisines_id: 28
    })

      expect(last_response.status).to eq 200
        end
    end

    describe "DELETE /dishes/id" do
        it "deletes correct data and http code" do
            delete "/dishes/28"

      expect(last_response.status).to eq 204
        end
    end
end




