# encoding: utf-8
require "rspec"
require "rack/test"
require "digest/sha1"
require "bson"
require "fog"

module Tinto
  module Persister
    module Upload
      attr_reader :account, :filename, :file, :type, :mmapped_file
      include Fog

      CACHE_DIR = "cache"
      ARCHIVE_DIR = "archive"

      def initialize(account, upload)
        @account      = account.to_s
        @filename     = upload[:filename]
        @file         = upload[:tempfile]
        @type         = upload[:type]
        @mmapped_file = @file.readlines.join
      end

      def sha1
        @sha1 = Digest::SHA1.hexdigest mmapped_file
      end
  
      def metadata
        { filename: filename, type: type, sha1: sha1 }
      end

      def cached_path
        File.join CACHE_DIR, account, sha1
      end

      def archived_path
        File.join ARCHIVE_DIR, account, sha1
      end

      def download_path
        File.exists? archived_path ? archived_path : url
      end

      def key
        "#{account}/#{sha1}"
      end

      def url
      end

      def check_or_create(dir=nil)
        FileUtils.mkdir_p dir unless File.exists? dir
      end

      def cache
        check_or_create File.join(CACHE_DIR, account)
        file.rewind
        File.open(cached_path, "wb") { |f| f.write @file.read }
      end

      def uncache
        File.delete cached_path
      end

      def archive
        check_or_create File.join(ARCHIVE_DIR, account)
        FileUtils.mv cached_path archived_path
      end

      def delete
        File.delete archived_path
      end
    end
  end
end

class Upload
  include Tinto::Persister::Upload
end

describe Upload do
  before :each do
    tempfile = Rack::Test::UploadedFile.new "file.txt", "text/plain"
    @file_hash = Digest::SHA1.hexdigest tempfile.readlines.join
    tempfile.rewind
    @upload = Upload.new(
      BSON::ObjectId.new,
      tempfile: tempfile,
      filename: tempfile.original_filename,
      type:     tempfile.content_type
    )
  end

  after :each do
    %w{ cache archive }.each { |dir| FileUtils.rm_r dir if File.exists? dir }
  end

  describe "#metadata" do
    it "returns file name, mime type and SHA1 hash" do
      @upload.metadata.should == {
        filename: "file.txt", type: "text/plain", sha1: @file_hash
      }
    end
  end

  describe "#cache" do
    it "writes file to disk cache folder" do
      @upload.cache.should be_true
      File.exists?(@upload.cached_path).should be_true
    end
  end

  describe "#url" do
    it "returns AWS S3 download url" do
      p @upload.url
    end
  end
end
