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

    def executable? path
      false
    end

    def size path
      doc = Rindle::Document.find_by_name File.basename(path)
      File.size File.join(Rindle.root_path, doc.path)
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
      filename = File.basename(path)
      case path
      when UNASSOCIATED_DOCUMENT_PATH, DOCUMENT_PATH
        doc = Rindle::Document.find_by_name $1
        doc = Rindle::Document.create $1 unless doc
        FileUtils.touch(File.join(Rindle.root_path, doc.path))
      end
      Rindle.save
      true
    end

    def mkdir(path)
      if path =~ COLLECTION_PATH
        col = Rindle::Collection.find_by_name $1
        Rindle::Collection.create($1) if col.nil?
      else
        false
      end
      Rindle.save
      true
    end

    def rmdir(path)
      if path =~ COLLECTION_PATH
        collection = Rindle::Collection.first :named => $1
        return false unless collection
        collection.destroy!
      else
        return false
      end
      Rindle.save
      true
    end

    def delete path
      case path
      when COLLECTION_DOCUMENT_PATH
        col = Rindle::Collection.find_by_name $1
        doc = Rindle::Document.find_by_name $2
        col.remove doc
      when DOCUMENT_PATH, UNASSOCIATED_DOCUMENT_PATH
        doc = Rindle::Document.find_by_name $1
        doc.delete!
      end
      Rindle.save
      true
    end

    def rename old, new
      case old
      when UNASSOCIATED_DOCUMENT_PATH
        doc = Rindle::Document.find_by_name $1
        if new =~ COLLECTION_DOCUMENT_PATH
          col = Rindle::Collection.find_by_name $1
          col.add doc
        end
        if doc and !doc.amazon?
          doc.rename! File.basename(new)
        else
          return false
        end
      when COLLECTION_DOCUMENT_PATH
        old_col = Rindle::Collection.find_by_name $1
        doc = Rindle::Document.find_by_name $2
        if new =~ COLLECTION_DOCUMENT_PATH
          new_col = Rindle::Collection.find_by_name $1
          unless old_col == new_col
            old_col.remove doc
            new_col.add doc
          end
          doc.rename! File.basename(new)
        else
          return false
        end
      when COLLECTION_PATH
        collection = Rindle::Collection.find_by_name $1
        if new =~ COLLECTION_PATH
          collection.rename! File.basename(new)
        else
          return false
        end
      else
        return false
      end
      Rindle.save
      true
    end

    def write_to path, body
      doc = Rindle::Document.find_by_name File.basename(path)
      if doc
        if path =~ COLLECTION_DOCUMENT_PATH
          col = Rindle::Collection.find_by_name $1
          col.add doc
        end
      else
        doc = Rindle::Document.create File.basename(path)
        File.open(File.join(Rindle.root_path, doc.path), 'w+') do |f|
          f.write body
        end
        if path =~ COLLECTION_DOCUMENT_PATH
          Rindle::Collection.find_by_name($1).add doc
        end
      end
      Rindle.save
      true
    end

    def read_file path
      doc = Rindle::Document.find_by_name File.basename(path)
      File.read File.join(Rindle.root_path, doc.path)
    end
  end
end
