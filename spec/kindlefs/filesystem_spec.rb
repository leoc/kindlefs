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

  describe '#contents' do
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

  describe '#file?' do
    it 'returns true if path to a collections document given' do
      @fs.file?('/collections/collection1/A test aswell.mobi').should == true
    end

    it 'returns false if path to collection given' do
      @fs.file?('/collections/collection1').should == false
    end
  end

  describe '#directory?' do
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

  describe '#executable?' do
    it 'should return false' do
      @fs.executable?('/some/path').should == false
    end
  end

  describe '#can_delete?' do
    it 'should return false for documents path' do
      @fs.can_delete?('/documents').should == false
    end

    it 'should return false for pictures path' do
      @fs.can_delete?('/pictures').should == false
    end

    it 'should return false for collections path' do
      @fs.can_delete?('/collections').should == false
    end

    it 'should return true for document path' do
      @fs.can_delete?('/documents/abc.pdf').should == true
    end

    it 'should return true for collection document path' do
      @fs.can_delete?('/collections/abc/my_document.pdf').should == true
    end

    it 'should return true for unasssociated document path' do
      @fs.can_delete?('/collections/my_document.pdf').should == true
    end
  end

  describe '#can_write?' do
    it 'should return false for root path' do
      @fs.can_write?('/').should == false
    end
  end

  describe '#can_mkdir?' do
    it 'should return false for root path' do
      @fs.can_mkdir?('/').should == false
    end

    it 'should return false for documents path' do
      @fs.can_mkdir?('/documents').should == false
    end

    it 'should return false for pictures path' do
      @fs.can_mkdir?('/pictures').should == false
    end

    it 'should return false for collections path' do
      @fs.can_mkdir?('/collections').should == false
    end

    it 'should return true for collection path' do
      @fs.can_mkdir?('/collections/collection').should == true
    end

    it 'should return false for collection document path' do
      @fs.can_mkdir?('/collections/collection/document.pdf').should == false
    end

    it 'should return false for document path' do
      @fs.can_mkdir?('/documents/document.pdf').should == false
    end
  end

  describe '#can_rmdir?' do
    it 'should return false for root path' do
      @fs.can_rmdir?('/').should == false
    end

    it 'should return false for documents path' do
      @fs.can_rmdir?('/documents').should == false
    end

    it 'should return false for pictures path' do
      @fs.can_rmdir?('/pictures').should == false
    end

    it 'should return false for collections path' do
      @fs.can_rmdir?('/collections').should == false
    end

    it 'should return true for collection path' do
      @fs.can_rmdir?('/collections/collection').should == true
    end

    it 'should return false for collection document path' do
      @fs.can_rmdir?('/collections/collection/document.pdf').should == false
    end

    it 'should return false for document path' do
      @fs.can_rmdir?('/documents/document.pdf').should == false
    end
  end

  describe '#touch' do
    before :all do
      @fs.touch '/collections/abc.rtf'
    end

    after :all do
      FileUtils.rm_f File.join(Rindle.root_path, '/documents/abc.rtf')
    end

    it 'should create an empty file for given path' do
      File.should exist File.join(Rindle.root_path, '/documents/abc.rtf')
    end
  end

  describe '#mkdir' do
    context 'given collection path' do
      it 'should create a new collection if non-existent' do
        @fs.mkdir '/collections/test collection'
        Rindle.collections.should have_key 'test collection'
      end
    end

    context 'given another path' do
      it 'should return false' do
        @fs.mkdir('/collections/test collection/something').should == false
      end
    end
  end

  describe '#rmdir' do
    context 'given collection path' do
      before :all do
        Rindle::Collection.create 'some collection'
      end

      context 'with existing collection' do
        it 'should delete the collection' do
          @fs.rmdir '/collections/some collection'
          Rindle.collections.should_not have_key 'some collection'
        end
      end

      context 'with non-existing collection' do
        it 'should return false' do
          ret = @fs.rmdir '/collections/some collection'
          ret.should == false
        end
      end
    end

    context 'given another path' do
      it 'should return false' do
        ret = @fs.rmdir '/collections/some collection/something'
        ret.should == false
      end
    end
  end

  describe '#delete' do
    context 'given a collection document path' do
      before :all do
        @fs.delete '/collections/collection1/A test aswell.mobi'
      end

      it 'should remove the document from the collection' do
        Rindle.collections['collection1'].
          include?('*18be6fcd5d5df39c1a96cd22596bbe7fe01db9b7').
          should == false
      end
    end

    context 'given a document path' do
      before :all do
        @fs.delete '/documents/A test aswell.mobi'
      end

      after :all do
        doc = Rindle::Document.create 'A test aswell.mobi', :data => 'Some dummy data'
        Rindle.collections['collection1'].add doc
      end

      it 'should remove the document from index' do
        Rindle.index.should_not have_key '*18be6fcd5d5df39c1a96cd22596bbe7fe01db9b7'
      end

      it 'should remove all references in collections' do
        Rindle.collections['collection1'].indices.
          should_not include '*18be6fcd5d5df39c1a96cd22596bbe7fe01db9b7'
      end

      it 'should delete the document file' do
        File.should_not exist File.join(Rindle.root_path, '/documents/A test aswell.mobi')
      end
    end

    context 'given an unassociated document path' do
      before :all do
        @fs.delete '/collections/This is a test document.rtf'
      end

      after :all do
        doc = Rindle::Document.create 'This is a test document.rtf', :data => 'Some dummy data'
      end

      it 'should remove the document from index' do
        Rindle.index.should_not have_key '*3a102b4032d485025650409b2f7753a1158b199d'
      end

      it 'should delete the document file' do
        File.should_not exist File.join(Rindle.root_path, '/documents/This is a test document.rtf')
      end
    end
  end

  describe '#rename' do
    context 'given an unassociated document path as `old` and a collection document path as `new`' do
      before :all do
        @doc = Rindle::Document.find_by_name 'This is a test document.rtf'
        @fs.rename '/collections/This is a test document.rtf', '/collections/collection1/Test.rtf'
      end

      after :all do
        Rindle.collections['collection1'].remove @doc
        @doc.rename! 'This is a test document.rtf'
      end

      it 'should rename the document' do
        @doc.filename.should == 'Test.rtf'
        File.should_not exist File.join(Rindle.root_path, '/documents/This is a test document.rtf')
        File.should exist File.join(Rindle.root_path, '/documents/Test.rtf')
      end

      it 'should add the document to the given collection' do
        Rindle.collections['collection1'].include?(@doc).should == true
      end
    end

    context 'given a collection document path as `old`' do
      context 'and a collection document path as `new`' do
        context 'is equal to the `old` one' do
          before :all do
            @doc = Rindle::Document.find_by_name 'A test aswell.mobi'
            @fs.rename '/collections/collection1/A test aswell.mobi',
                       '/collections/collection1/test aswell.mobi'
          end

          after :all do
            @doc.rename! 'A test aswell.mobi'
          end

          it 'should rename the document' do
            File.should exist File.join(Rindle.root_path, '/documents/test aswell.mobi')
          end
        end

        context 'is not equal to the `old` one' do
          before :all do
            @doc = Rindle::Document.find_by_name 'A test aswell.mobi'
            @fs.rename '/collections/collection1/A test aswell.mobi',
                       '/collections/collection2/A test aswell.mobi'
          end

          after :all do
            Rindle.collections['collection2'].remove @doc
            Rindle.collections['collection1'].add @doc
          end

          it 'should remove the document from the old collection' do
            @doc.collections.map(&:name).should_not include 'collection1'
          end

          it 'should add the document to the new collection' do
            @doc.collections.map(&:name).should include 'collection2'
          end
        end
      end
    end

    context 'given a collection path as `old`' do
      context 'and a collection path as `new`' do
        before :all do
          @col = Rindle::Collection.find_by_name 'collection1'
          @fs.rename '/collections/collection1',
                     '/collections/collection_renamed'
        end

        after :all do
          @col.rename! 'collection1'
        end

        it 'should rename the collection' do
          @col.name.should == 'collection_renamed'
        end
      end
    end
  end

  describe '#write_to' do
    context 'given document exists' do
      context 'and in collection document path' do
        before :all do
          @doc = Rindle::Document.find_by_name 'A test aswell.mobi'
          @fs.write_to '/collections/collection2/A test aswell.mobi',
                       'Some dummy data'
        end

        after :all do
          Rindle.collections['collection2'].remove @doc
        end

        it 'should add the document to the collection' do
          Rindle.collections['collection2'].include?(@doc).should == true
        end
      end
    end

    context 'given document does not exist' do
      before :all do
        @fs.write_to '/collections/My test.mobi',
                     'Some dummy data'
        @doc = Rindle::Document.find_by_name 'My test.mobi'
      end

      after :all do
        @doc.delete!
      end

      it 'should write the file to `documents` folder' do
        File.read(File.join(Rindle.root_path, @doc.path)).
          should == 'Some dummy data'
      end

      it 'should add the document to the index' do
        Rindle.index['*5c4dc5c9e385385cbcaf1beedef7690c165a39ca'].should == @doc
      end
    end

    context 'given document does not exist and in collection document path' do
      before :all do
        @fs.write_to '/collections/collection2/My test.mobi',
                     'Some dummy data'
        @doc = Rindle::Document.find_by_name 'My test.mobi'
      end

      after :all do
        @doc.delete!
      end

      it 'should write the file to `documents` folder' do
        File.read(File.join(Rindle.root_path, @doc.path)).
          should == 'Some dummy data'
      end

      it 'should add the document to the index' do
        Rindle.index['*5c4dc5c9e385385cbcaf1beedef7690c165a39ca'].should == @doc
      end

      it 'should add the new document to the collection' do
        Rindle.collections['collection2'].
          include?('*5c4dc5c9e385385cbcaf1beedef7690c165a39ca').
          should == true
      end
    end
  end

  describe '#read_file' do
    it 'should return the file data' do
      data = @fs.read_file '/collections/collection1/A test aswell.mobi'
      data.should == 'Some dummy data'
    end
  end
end
