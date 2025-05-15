# Genius API Client

This Ruby on Rails (ROR) application uses the [Genius API](https://docs.genius.com/) to fetch the songs for a given artist. The app is tested. The UI is not styled.

To use the app:
1. Install Ruby system-wide with [ROR’s instructions](https://guides.rubyonrails.org/install_ruby_on_rails.html), or do it with [rbenv](https://github.com/rbenv/rbenv)
   1. If you use rbenv, install the Ruby version that’s stated in the `.ruby-version` file
1. Clone this repository
1. Get a client access token from Genius
   1. You must [sign up](https://genius.com/api-clients) for a Genius account if you don’t have one already
   2. Follow the instructions in the “Access for Apps Without Users” section in the right sidebar [in their documentation](https://docs.genius.com/#/authentication-h1) to get a token
1. Set the client access token as the value to the `GENIUS_API_TOKEN` key in the `.env` file
   1. For example, `GENIUS_API_TOKEN=ABCD1234`
1. Within the repository’s directory, run
   ```shell
   bundle
   ```
1. Start the local server by running
   ```shell
   bundle exec bin/rails server
   ```
1. Navigate to `http://127.0.0.1:3000/` in a browser

To run the tests:
```shell
bundle exec bin/rails test:all
```
