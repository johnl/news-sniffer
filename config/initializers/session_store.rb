# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_newssniffer.git_session',
  :secret      => '2df01c59d5404dc3eafd6391102e20997e4b91542b6359b5ab22652404a914c15fe3cc0b41a34fc95076d5c614d02336982b59bd0f109e5479573546b211bce1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
