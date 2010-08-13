
class FileMagic
  def self.mime filename
    mime_type = `file --brief --mime-type #{filename}`.strip()
  end
end
