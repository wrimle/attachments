require 'helper'
require 'iconv'

class TestAttachments < Test::Unit::TestCase
  context "Parse test cases without crashes" do
    setup do
      @extract = Attachments::Extract.new [ "text/plain", "image/jpeg" ]
    end

    teardown do
      @extract.close
    end

    should "parse text/plain + text/html" do
      assert_nothing_raised do
        @extract.parse "./test/data/mail_0001.eml"
      end
    end

    should "parse text/plain with UTF-8 and image/jpeg" do
      assert_nothing_raised do
        @extract.parse "./test/data/mail_0002.eml"
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
      @extract.parse "./test/data/mail_0001.eml"
    end

    teardown do
      @extract.close
    end
  end
end

