require 'gettext'
require 'libglade2'
require 'gtk2'

class AboutDialog

  include GetText

  attr :builder

  def initialize(path_or_data, root = nil, domain = nil, localedir = nil)
      bindtextdomain(domain, localedir, nil, "UTF-8")
      @builder = Gtk::Builder::new
      @builder.add_from_file(path_or_data)
      @builder.connect_signals { |handler| method(handler) }
  end

end