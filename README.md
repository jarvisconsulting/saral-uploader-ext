# SaralUploaderExt
Short description and motivation.

## Usage
How to use my plugin.
create a 'config/saral_uploader_ext.yml' file and define these config:

defaults: &DEFAULTS
gcloud_bucket: <%= ENV['G_CLOUD_BUCKET'] %>
gcloud_project_id: <%= ENV['G_CLOUD_PROJECT_ID'] %>
gcloud_keyfile: <%= ENV['G_CLOUD_KEYFILE'] %>
signed_url_expiration_time_in_seconds: <%= ENV['SIGNED_URL_EXPIRATION_TIME_IN_SECONDS'] %>

development:
<<: *DEFAULTS

test:
<<: *DEFAULTS

production:
<<: *DEFAULTS

## Installation
Add this line to your application's Gemfile:

```ruby
gem "saral_uploader_ext"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install saral_uploader_ext
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
