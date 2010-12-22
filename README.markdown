TV Program API
===================

Introduction
-------------------

This application uses screen scraping to get the TV program listing available in Poland. It stores it in the database and provides an easy web service for accessing it.

Installation:
--------------------

* Download the source code
* Install gems

				$ bundle install
				
* Copy database config and create databases

				$ cp config/database.yml.config config/database.yml
				$ cp db/tvapi.sqlite.example db/tvapi.sqlite
				$ cp db/tvapi.sqlite.example db/test.sqlite

Run tests first:

				$ rspec spec

Run the updater (by default it will download lots of the data from the internet)

				$ ruby bin/update_programs.rb

Run the server 

				$ ruby server/server.rb

And check the link [http://localhost:4567](http://localhost:4567) for further instructions.

You can see the working system on [http://tvapi.staskie.com](http://tvapi.staskie.com)

This application was created by [Dominik Staskiewicz](http://twitter.com/staskie)
