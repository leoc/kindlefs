require "spec_helper"

describe KindleFS::Filesystem do
  before(:all) do
    Rindle.load(kindle_root)
    @fs = KindleFS::Filesystem.new
  end

  context ' regular expressions' do
    it 'should match root path correctly' do
      '/'.should match(KindleFS::Filesystem::ROOT_PATH)
      '/collections'.should_not match(KindleFS::Filesystem::ROOT_PATH)
    end

    it 'should match the documents path correctly' do
      '/documents'.should match(KindleFS::Filesystem::DOCUMENTS_PATH)
      '/collections'.should_not match(KindleFS::Filesystem::DOCUMENTS_PATH)
      '/documents/dummy'.should_not match(KindleFS::Filesystem::DOCUMENTS_PATH)
    end

    it 'should match the collections path correctly' do
      '/collections'.should match(KindleFS::Filesystem::COLLECTIONS_PATH)
      '/documents'.should_not match(KindleFS::Filesystem::COLLECTIONS_PATH)
      '/collections/dummy'.should_not match(KindleFS::Filesystem::COLLECTIONS_PATH)
    end
  end

  context '#file?' do
    it 'returns true if path to a collections document given' do
      @fs.file?('/collections/collection1/A test aswell.mobi').should == true
    end

    it 'returns false if path to collection given' do
      @fs.file?('/collections/collection1').should == false
    end
  end

  context '#directory?' do
    it 'returns true if path to root folders given' do
      @fs.directory?('/collections').should == true
      @fs.directory?('/documents').should == true
      @fs.directory?('/pictures').should == true
    end

    it 'returns true if path to collection given' do
      @fs.directory?('/collections/collection1').should == true
    end

    it 'returns false if path to collections document given' do
      @fs.directory?('/collections/collection1/A test aswell.mobi').should == false
    end

    it 'returns false if path to unassociated document given' do
      @fs.directory?('/collections/test.mobi').should == false
    end

    it 'returns false if path to document given' do
      @fs.directory?('/documents/test.mobi').should == false
    end
  end

  context '#contents' do
    it 'lists view options' do
      list = @fs.contents('/')
      list.should =~ [ 'collections', 'documents', 'pictures' ]
    end
    it 'lists all documents' do
      list = @fs.contents '/documents'
      list.should =~ [
                      'A book in another collection.mobi',
                      'A test aswell.mobi',
                      'Definitely a Test.pdf',
                      'Salvia Divinorum Shamanic Plant-asin_B001UQ5HVA-type_EBSP-v_0.azw',
                      'The Adventures of Sherlock Holme-asin_B000JQU1VS-type_EBOK-v_0.azw',
                      'This is a test document.rtf'
                     ]
    end
    it 'lists collections and unassociated documents' do
      list = @fs.contents('/collections')
      list.should =~ [ 'collection1', 'collection2', 'amazon books',
                       "This is a test document.rtf" ]
    end
    it 'lists documents in a collection' do
      list = @fs.contents('/collections/collection1')
      list.should =~ [ 'A test aswell.mobi', 'Definitely a Test.pdf' ]
    end

  end
end
