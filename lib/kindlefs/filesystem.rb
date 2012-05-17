require 'fusefs'
require 'rindle/mixins/regexp'

module KindleFS
  class Filesystem < FuseFS::FuseDir
    ROOT_PATH        = /^\/$/
    COLLECTIONS_PATH = /^\/collections$/.freeze
    DOCUMENTS_PATH   = /^\/documents$/.freeze
    PICTURES_PATH    = /^\/pictures$/.freeze
    COLLECTION_NAME  = /([A-Za-z0-9_\-\s'"\.]+)/i.freeze
    COLLECTION_PATH  = /^#{COLLECTIONS_PATH.strip}\/#{COLLECTION_NAME.strip}$/.freeze
    DOCUMENT_NAME    = /([A-Za-z0-9_\s\-]+\.(mobi|epub|rtf|pdf|azw|azw1)+)/i.freeze
    COLLECTION_DOCUMENT_PATH   = /^#{COLLECTIONS_PATH.strip}\/#{COLLECTION_NAME.strip}\/#{DOCUMENT_NAME.strip}$/.freeze
    UNASSOCIATED_DOCUMENT_PATH = /^#{COLLECTIONS_PATH.strip}\/#{DOCUMENT_NAME.strip}$/.freeze
    DOCUMENT_PATH    = /^#{DOCUMENTS_PATH.strip}\/#{DOCUMENT_NAME.strip}$/.freeze

    def contents path
      case path
      when ROOT_PATH
        [ 'collections', 'documents', 'pictures' ]
      when COLLECTIONS_PATH
        Rindle::Collection.all.map(&:name) + Rindle::Document.unassociated.map(&:filename)
      when DOCUMENTS_PATH
        Rindle::Document.all.map(&:filename)
      when COLLECTION_PATH
        collection = Rindle::Collection.first :named => $1
        collection.documents.map(&:filename)
      else
        []
      end
    end

    def file?(path)
      case path
      when DOCUMENT_PATH
        return true
      when COLLECTION_DOCUMENT_PATH
        col = Rindle::Collection.find_by_name $1
        doc = Rindle::Document.find_by_name $2
        return doc && col.include?(doc)
      when UNASSOCIATED_DOCUMENT_PATH
        doc = Rindle::Document.find_by_name $1
        return doc.collections.empty? if doc
      end
      false
    end

    def directory?(path)
      case path
      when COLLECTIONS_PATH, DOCUMENTS_PATH, PICTURES_PATH
        true
      when COLLECTION_PATH
        Rindle::Collection.exists?(:named => $1)
      else
        false
      end
    end

    def executable?(path)
      false
    end

    def size(path)
      read_file(path).size
    end

    def can_delete?(path)
      case path
      when DOCUMENTS_PATH, PICTURES_PATH, COLLECTIONS_PATH
        false
      else
        true
      end
    end

    def can_write?(path)
      if path !~ ROOT_PATH
        true
      else
        false
      end
    end

    def can_mkdir?(path)
      case path
      when COLLECTION_PATH
        true
      else
        false
      end
    end

    def can_rmdir?(path)
      case path
      when COLLECTION_PATH
        true
      else
        false
      end
    end

    def touch(path, val = 0)
      puts "touch(#{path} --- #{val})"
    end

    def mkdir(path)
      if path =~ COLLECTION_PATH
        collection = Rindle::Collection.first :named => $1
        collection = Rindle::Collection.create($1) if collection.nil?
        puts Rindle::Collection.all.map(&:name).inspect
        puts collection.to_hash.inspect
        true
      else
        false
      end
    end

    def rmdir(path)
      if path =~ COLLECTION_PATH
        collection = Rindle::Collection.first :named => $1
        if collection
          collection.destroy!
          return true
        end
      end
      false
    end

    def delete path
      puts "delete(#{path})"
      # TODO: if collection_doc_path, remove from collection
      # TODO: if document_path, remove document and all references
      # TODO: if unassociated document path, remove doc and all refs
    end

    def rename old, new
      puts "rename(#{old}, #{new})"
      case old
      when UNASSOCIATED_DOCUMENT_PATH
        document = Rindle::Document.find_by_name $1
        if document and !document.amazon?
          document.rename! File.basename(new)
          true
        else
          false
        end
        # TODO: if new is collection_document_path => add to collection
        # TODO: if new is unassociated_document_path => rename document
      when COLLECTION_DOCUMENT_PATH
        doc = Rindle::Document.find_by_name $2
        # TODO: if new is COLLECTION_DOCUMENT_PATH for the same collection
        # => rename
        # TODO: if new is COLLECTION_DOCUMENT_PATH for another collection =>
        # remove from old collection, add to new collection
      when COLLECTION_PATH
        collection = Rindle::Collection.find_by_name $1
        if new =~ COLLECTION_PATH
          collection.rename! File.basename(new)
          true
        else
          false
        end
      else
        false
      end
    end

    def write_to path, body
      # TODO: if doc exists and unassociated_path => do nothing
      # else if collection_path => add to collection
      # TODO: if doc does not exist write file into kindle_root/documents
      # if path is collection_path add to collection
      puts "write_to(#{path}, #{body})"
    end

    def read_file path
      puts "read_file(#{path})"
      "dummy text der da in der Datei steht ...\n"
      # TODO: return actual file data
    end
  end
end
