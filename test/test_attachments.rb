require 'helper'

class TestAttachments < Test::Unit::TestCase
  def setup
    @extract = Attachments::Extract.new [ "text/plain" ]
    @extract.parse "./test/data/mail_0001.eml"
  end

  def teardown
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
end
