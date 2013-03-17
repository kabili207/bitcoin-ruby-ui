#!/usr/bin/env ruby

require 'libglade2'
require File.expand_path(File.dirname(__FILE__) + '/main.rb')


# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "main.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  o = MainGlade.new(PROG_PATH, nil, PROG_NAME)
  
  win = o.glade["window1"]
  win.title = PROG_NAME
  win.show_all
  
  Gtk.main
end