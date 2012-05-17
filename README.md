# KindleFS

KindleFS is a FuseFS that mounts a Kindles data via Rindle and allows
the management of the kindles collection information via filesystem tools.

## Installation

Add this line to your application's Gemfile:

    gem 'kindlefs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kindlefs

## Usage

Just mount the kindle into some folder.

    $ kindlefs /path/to/kindle/root /path/to/mountpoint

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
