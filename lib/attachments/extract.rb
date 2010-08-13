require 'rubygems'
require 'uuidtools'
require 'mail'


module Attachments
  module Error
    class Base < StandardError; end
    class SaveFailed < Base; end
  end


  # Extract attachments of specific types from emails and save them in files
  class Extract
    UNCERTAIN_TYPES = [ "application/octet-stream" ].to_set

    def initialize include_types = [ "text/plain" ]
      @include_types = include_types
      reset
    end

    def close
      files.each do |f|
        FileUtils::rm(f[:filename])
      end
      reset
    end

    def parse filename
      @last_parsed = filename

      # Load the email
      mail = Mail.read(filename)

      # To and from is important when sending mail to db
      @to = mail.to

      @from = mail.from

      # Parse parts recursively until it is not multipart
      # Ignore types that are not suited for forwarding
      parse_part mail
    end

    def to 
      @to || nil
    end

    def from
      @from || nil
    end

    def name
      @name
    end

    def files
      @files
    end

    def last_parsed
      @last_parsed
    end


    private
    # Use close
    def reset
      @last_parsed = nil
      @to = nil
      @name = nil
      @from = nil
      @files = []
    end

    def parse_part mail
      # Filter parts with a type that is not of interest
      ct = mail.content_type.split(/;/, 2)[0] if mail.content_type
      unless(mail.multipart? || (ct && @include_types.include?(ct)))
        return
      end

      # If part is multipart, recurse
      if mail.multipart?
        mail.parts.each do |p|
          parse_part p
        end
      else
        # Grab filename from content parameters, and make sure its sane
        @name = mail.content_type_parameters['name'] || "unnamed"
        @name.gsub! /[^\w\.\-]/, '_' # Sanitize

        # Make it unique
        uuid = UUIDTools::UUID.random_create.hexdigest

        # The filename used for storage
        filename = "#{@name}.#{uuid}"
        filepath = "/tmp/#{filename}" 

        # Save part as it is of a supported type
        f = File.new(filepath, "wb")
        f.write(mail.body.decoded)
        f.close

        unless File.exists?(filepath)
          raise Error::SaveFailed, "Save failed for ", filepath, "\n"
          return
        end

        # Sort out the mime type
        mime_type = ct
        if(UNCERTAIN_TYPES.include? mime_type)
          mime_type = FileMagic::mime filename
        end

        # Save meta-data for further processing
        @files << { :name => @name, :tmpfile => filepath, :save_as => name, :upload_to => filename, :mime_type => mime_type, :from => @from, :to => @to }
      end
    end
  end
end
