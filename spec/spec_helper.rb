require 'rindle'
require 'kindlefs'

def kindle_root; File.join(File.dirname(__FILE__), 'data', 'kindle'); end

File.open 'spec/data/kindle/system/collections.json', 'w+' do |f|
  f.write <<JSON
{
    "collection1@en-US":{
        "items":["*18be6fcd5d5df39c1a96cd22596bbe7fe01db9b7", "*0849dd9b85fc341d10104f56985e423b3848e1f3"],
        "lastAccess": 1298745909919
    },
    "collection2@en-US":{
        "items":["*440f49b58ae78d34f4b8ad3233f04f6b8f5490c2"],
        "lastAccess": 1298745909918
    },
    "amazon books@en-US":{
        "items":["#B001UQ5HVA^EBSP","#B000JQU1VS^EBOK"],
        "lastAccess": 1298745909917
    }
}
JSON
end

system 'rm -rf spec/data/kindle/documents/*'

[ 'A book in another collection.mobi',
'A test aswell.mobi',
'Definitely a Test.pdf',
'Salvia Divinorum Shamanic Plant-asin_B001UQ5HVA-type_EBSP-v_0.azw',
'The Adventures of Sherlock Holme-asin_B000JQU1VS-type_EBOK-v_0.azw',
'This is a test document.rtf' ].each do |filename|
  File.open File.join('spec/data/kindle/documents', filename), 'w+' do |f|
    f.write 'Some dummy data'
  end
end

# this is to reset the Singleton'ish nature of the Kindle module
class Rindle
  def self.reset
    self.class_variables.each do |var|
      eval "#{var} = nil"
    end
  end
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end
