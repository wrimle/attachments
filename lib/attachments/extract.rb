# encoding: UTF-8

require 'rubygems'
require 'uuidtools'
require 'fileutils'
require 'mail'
require 'iconv'


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
        FileUtils::rm(f[:tmpfile])
      end
      reset
    end

    def parse filename_or_hash
      hash = case
             when filename_or_hash.is_a?(String) then
               { :filename => filename_or_hash }
             when filename_or_hash.is_a?(Hash) then
               filename_or_hash
             else
               {}
             end

      content = case
                when hash[:filename] then
                  read_file(hash[:filename])
                when hash[:content] then
                  hash[:content]
                when hash[:stream] then
                  hash[:stream].read()
                else
                  nil
                end

      parse_data content if content
    end

    def parse_file filename
      @last_parsed = filename
      content = read_file filename
      parse_data content
    end

    def parse_data raw_mail_data
      @mail = Mail.new(raw_mail_data)

      # Parse parts recursively until it is not multipart
      # Ignore types that are not suited for forwarding
      parse_part @mail
    end

    def to 
      (@mail && @mail.to) || nil
    end

    def from
      (@mail && @mail.from) || nil
    end

    def subject
      (@mail && @mail.subject) || nil
    end

    def text_body
      if(@mail && @mail.text_part && @mail.text_part.body)
        m = @mail.text_part.body.decoded
        charset = @mail.text_part.charset
        text = charset ? Iconv.conv("utf-8", charset, m) : m
        (text.respond_to? :force_encoding) ? text.force_encoding("utf-8") : text
      elsif(@mail && @mail.body && @mail.content_type.to_s.include?("text/plain"))
        m = @mail.body.decoded
        charset = @mail.charset
        text = charset ? Iconv.conv("utf-8", charset, m) : m
        (text.respond_to? :force_encoding) ? text.force_encoding("utf-8") : text
      else
        nil
      end
    end

    def html_body
      if(@mail && @mail.text_part && @mail.text_part.body)
        m = @mail.text_part.body.decoded
        charset = @mail.text_part.charset
        charset ? Iconv.conv("utf-8", charset, m) : m
      else
        nil
      end
    end

    def mail
      @mail
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
      @name = nil
      @mail = nil
      @files = []
    end

    def read_file filename
      # Load the email as binary to avoid encoding exceptions
      file = File.new(filename, "rb")
      content = file.read()
      file.close()
      content
    end

    def parse_part mail
      # Filter parts with a type that is not of interest
      if mail.content_type
        ct, charset = mail.content_type.split(/;/, 2)
      end
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


        body = case ct
               when "text/plain" then
                 m = mail.body.decoded
                 if charset && charset.match(/charset=/i)
                   charset.gsub!(/charset=/i, "")
                   charset.strip!
                 else
                   charset = nil
                 end
                 begin
                   if charset
                     m.force_encoding(charset)
                   end
                   m.encode("utf-8")
                 rescue
                   # Ruby 1.8 doesn't know encode
                   if charset 
                     Iconv.conv("utf-8", charset, m)
                   else
                     m
                   end
                 end
               else
                 mail.body.decoded
               end

        # Save part as it is of a supported type
        f = File.new(filepath, "wb")
        f.write(body)
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
        @files << { :name => @name, :tmpfile => filepath, :save_as => name, :upload_to => filename, :mime_type => mime_type  }
      end
    end
  end
end
