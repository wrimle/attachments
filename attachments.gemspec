# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{attachments}
  s.version = "0.0.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rune Myrland"]
  s.date = %q{2011-04-07}
  s.description = %q{It's original intention is as a helper class class for filtering email attachments before forwarding. The extracted attachments are saved in the /tmp directory.}
  s.email = %q{rune@epubify.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "attachments.gemspec",
    "lib/attachments.rb",
    "lib/attachments/extract.rb",
    "lib/attachments/filemagic.rb",
    "test/data/mail_0001.eml",
    "test/data/mail_0002.eml",
    "test/data/mail_0002.jpg",
    "test/data/mail_0004.eml",
    "test/helper.rb",
    "test/test_attachments.rb"
  ]
  s.homepage = %q{http://github.com/wrimle/attachments}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Extract mail parts of specified mime types.}
  s.test_files = [
    "test/helper.rb",
    "test/test_attachments.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mail>, [">= 2.2.5"])
      s.add_runtime_dependency(%q<uuidtools>, [">= 2.1.1"])
    else
      s.add_dependency(%q<mail>, [">= 2.2.5"])
      s.add_dependency(%q<uuidtools>, [">= 2.1.1"])
    end
  else
    s.add_dependency(%q<mail>, [">= 2.2.5"])
    s.add_dependency(%q<uuidtools>, [">= 2.1.1"])
  end
end

