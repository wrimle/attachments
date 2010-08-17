# encoding: UTF-8

require 'helper'
require 'iconv'

class TestAttachments < Test::Unit::TestCase
  def compare_extractors a, b
    (0...a.files.length).each do |i|
      tmp_a = a.files[i][:tmpfile]
      tmp_b = b.files[i][:tmpfile]

      isIdentical = FileUtils::compare_file(tmp_a, tmp_b)
      assert(isIdentical)
    end
  end

  context "Parse test cases without crashes" do
    setup do
      @extract = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
    end

    teardown do
    end

    should "parse test mails without raising exceptions" do
      Dir.glob("./test/data/mail_*.eml") do |filename|
        assert_nothing_raised do
          @extract.parse_file filename
        end
        @extract.close
      end
    end

    should "return valid encoding in all text bodies" do
      return unless "".respond_to?(:valid_encoding?)

      Dir.glob("./test/data/mail_*.eml") do |filename|
        @extract.parse_file filename
        assert @extract.text_body.valid_encoding?
        @extract.close
      end
    end
  end


  context "Just text text/plain and text/html" do
    setup do
      @extract = Attachments::Extract.new [ "text/plain" ]
      @extract.parse "./test/data/mail_0001.eml"
    end

    teardown do
      @extract.close
    end

    should "extract a part mail_001" do
      assert_equal(@extract.files.length, 1)
    end

    should "extract part of type text/plain" do
      assert_equal(@extract.files[0][:mime_type], "text/plain")
    end

    should "create files from the attachments" do
      @extract.files.each do |f|
        assert File::exists?(f[:tmpfile])
        puts f.inspect
      end
    end

    should "remove tmp files on close" do
      tmpfile = @extract.files[0][:tmpfile]
      @extract.close
      assert !File::exists?(tmpfile)
    end


    should "save as text/plain as utf-8" do
      tmpfile = @extract.files[0][:tmpfile]
      m = File.read(tmpfile)
      assert_nothing_raised do
        # Provoke an exception if not valid utf-8
        Iconv.conv("ISO-8859-1", "utf-8", m)
      end
    end
  end

  context "UTF-8 and text/plain and image attachment" do
    setup do
      @extract = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
      @extract.parse "./test/data/mail_0002.eml"
    end

    teardown do
      @extract.close
    end


    should "not modify image" do
      tmpfile = @extract.files[1][:tmpfile]

      isIdentical = FileUtils::compare_file(tmpfile, "test/data/mail_0002.jpg")
      assert(isIdentical)
    end
  end

  context "convenience accessors" do
    setup do
      @extract = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
      @extract.parse "./test/data/mail_0001.eml"
    end

    teardown do
      @extract.close
    end

    should "not raise exceptions" do
      assert_nothing_raised do
        @extract.text_body
      end
      assert_nothing_raised do
        @extract.html_body
      end
      assert_nothing_raised do
        @extract.subject
      end
      assert_nothing_raised do
        @extract.to
      end
      assert_nothing_raised do
        @extract.from
      end
      assert_nothing_raised do
        @extract.mail
      end
    end
  end

  context "Parse parameters" do
    setup do
      @a = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
      @b = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
    end

    teardown do
    end


    should "handle straight filename" do
      Dir.glob("./test/data/mail_*.eml") do |filename|
        assert_nothing_raised do
          @a.parse_file filename
          @b.parse filename

          compare_extractors(@a, @b)
        end
        @a.close
        @b.close
      end
    end


    should "handle filename in hash" do
      Dir.glob("./test/data/mail_*.eml") do |filename|
        assert_nothing_raised do
          @a.parse_file filename
          @b.parse({ :filename => filename })

          compare_extractors(@a, @b)
        end
        @a.close
        @b.close
      end
    end


    should "handle content in hash" do
      Dir.glob("./test/data/mail_*.eml") do |filename|
        assert_nothing_raised do
          @a.parse_file filename

          f = File.new(filename, "rb")
          content = f.read()
          f.close 
          @b.parse({ :content => content })

          compare_extractors(@a, @b)
        end
        @a.close
        @b.close
      end
    end


    should "handle stream in hash" do
      Dir.glob("./test/data/mail_*.eml") do |filename|
        assert_nothing_raised do
          @a.parse_file filename

          f = File.new(filename, "rb")
          @b.parse({ :stream => f })
          f.close 

          compare_extractors(@a, @b)
        end
        @a.close
        @b.close
      end
    end
  end
end

