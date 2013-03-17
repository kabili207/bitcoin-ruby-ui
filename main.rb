#!/usr/bin/env ruby
#
# This file is gererated by ruby-glade-create-template 1.1.4.
#
require 'gettext'
require 'libglade2'
require 'gtk2'
require 'bitcoin'

class MainGlade
  include GetText
  USERNAME = 'user'
  PASSWORD = 'pass'

  attr :glade
  attr :builder
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @builder = Gtk::Builder::new
    @builder.add_from_file(path_or_data)
    @builder.connect_signals{ |handler| method(handler) }
    #@builder.translation_domain = domain
    
    @transaction_tree = @builder.get_object("transactions_treeview")
    
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Time", renderer)
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      time_int = iter[0]
      renderer.text = Time.at(time_int).strftime('%D %R')
    end
    @transaction_tree.append_column(col)
    
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Type", renderer, :text => 3)
    @transaction_tree.append_column(col)
    
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Address", renderer, :text => 1)
    @transaction_tree.append_column(col)
    
    renderer = Gtk::CellRendererText.new
    renderer.foreground = "red"
    col = Gtk::TreeViewColumn.new("Amount", renderer, :text => 2)
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      category = iter[3]
      amount = iter[2]
      
      renderer.text = sprintf('%.10f', amount).gsub(/0+$/, '')
      if amount > 0
        renderer.foreground_set = false
      else
        renderer.foreground_set = true
      end
        
    end
    @transaction_tree.append_column(col)
    
  end
  
  def on_window1_show(widget)
    @client = Bitcoin::Client.new(USERNAME, PASSWORD)
    update_balance
    update_transactions
  end

  def on_window1_destroy(widget)
    Gtk.main_quit
  end
  
  def on_menu_quit_activate(widget)
    Gtk.main_quit
  end
  
  def update_balance
    l = @builder.get_object('balance_label')
    l.text = @client.balance.to_s
  end
  
  def update_transactions
    store = Gtk::ListStore.new(Integer, String, Float, String)
   
    trans = @client.list_transactions(nil)
    i = nil
    trans.each do |t|
      i = store.append
      i.set_value(0, t['time'])
      i.set_value(1, t['address'])
      i.set_value(2, t['amount'])
      i.set_value(3, t['category'])
    end
    tree = @transaction_tree
    tree.model = store
  end
  
  
end
