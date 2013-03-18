require 'gettext'
require 'libglade2'
require 'gtk2'
require 'bitcoin'
require File.expand_path(File.dirname(__FILE__) + '/transaction.rb')
require File.expand_path(File.dirname(__FILE__) + '/about_dialog.rb')

class MainWindow

  include GetText

  # TODO: Extract these to user configured values
  USERNAME = 'user'
  PASSWORD = 'pass'

  attr :builder

  # TODO: Find GtkBuilder equivalents to Glade parameters
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil)
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @builder = Gtk::Builder::new
    @builder.add_from_file(path_or_data)
    @builder.connect_signals { |handler| method(handler) }
    #@builder.translation_domain = domain

    @transaction_tree = @builder.get_object("transactions_treeview")

    populate_transaction_columns()

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

  def on_menu_about_activate(widget)
    o = AboutDialog.new("about.glade", nil, nil)

    win = o.builder.get_object("aboutdialog1")
    win.show_all
  end

  def update_balance
    l = @builder.get_object('balance_label')
    l.text = @client.balance.to_s
  end

  def update_transactions
    store = Gtk::ListStore.new(Time, String, Float, String, Float, String, Object)

    # TODO: Extract count to a user configured value
    t_hashes = @client.list_transactions('*', 10000).reverse
    transactions = convert_transaction_hash(t_hashes)

    i = nil
    transactions.each do |t|
      i = store.append
      i.set_value(0, t.time)
      i.set_value(1, t.address)
      i.set_value(2, t.amount)
      i.set_value(3, t.category)
      i.set_value(4, t.fee)
      i.set_value(5, t.tx_id)
      i.set_value(6, t.payment_to_self)
    end
    list_store_sort = Gtk::TreeModelSort.new store
    list_store_sort.set_sort_func(0) { |i, j| i[0] <=> j[0] }
    list_store_sort.set_sort_column_id(0, Gtk::SORT_DESCENDING)
    @transaction_tree.model = list_store_sort
  end

  def populate_transaction_columns
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Time", renderer)
    col.sort_column_id=0
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      time_int = iter[0]
      renderer.text = time_int.strftime('%D %R')
    end
    @transaction_tree.append_column(col)

    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Type", renderer, :text => 3)
    col.sort_column_id=3
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      case iter[3]
        when 'send'
          renderer.text = 'Sent to'
        when 'receive'
          renderer.text = 'Received with'
        when 'move'
          renderer.text = 'Moved to'
      end
      renderer.text = 'Payment to self' if iter[6]
    end
    @transaction_tree.append_column(col)

    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new("Address", renderer, :text => 1)
    col.sort_column_id=1
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      renderer.text = (iter[6] ? '(n/a)' : iter[1])
    end
    @transaction_tree.append_column(col)

    renderer = Gtk::CellRendererText.new
    renderer.foreground = "red"
    col = Gtk::TreeViewColumn.new("Amount", renderer, :text => 2)
    col.sort_column_id=2
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      category = iter[3]
      amount = iter[2]
      fee = iter[4]

      renderer.text = sprintf('%.10f', (iter[6] ? 0 : amount) + fee).gsub(/0+$/, '')
      if amount > 0
        renderer.foreground_set = false
      else
        renderer.foreground_set = true
      end

    end
    @transaction_tree.append_column(col)
  end

  def convert_transaction_hash(t_hashes)
    transactions = Array.new
    prev_trans = nil
    not_valid = false

    t_hashes.each do |t_hash|
      curr_trans = Transaction.new(t_hash)
      not_valid = false
      insert_prev = false

      unless prev_trans.nil?
        # Transactions also include simple transfers between
        # 'accounts' and aren't always labeled in the 'move'
        # category so we must remove them from the display.
        # https://en.bitcoin.it/wiki/Accounts_explained
        same_tx = (curr_trans.tx_id == prev_trans.tx_id)
        same_addr = (curr_trans.address == prev_trans.address)
        inverse_amnt = ((curr_trans.amount * -1) == prev_trans.amount)
        diff_acct = (curr_trans.account != prev_trans.account)

        if same_tx && same_addr && inverse_amnt && diff_acct
          # We still want to show actual transfers to ourselves
          if curr_trans.fee != prev_trans.fee
            not_valid = insert_prev = curr_trans.fee == 0
            curr_trans.payment_to_self = true
            prev_trans.payment_to_self = true
          else
            not_valid = true
          end
          prev_trans = transactions.last unless insert_prev
        else
          insert_prev = true
          if same_tx
            # only show fees once
            curr_trans.fee = 0
            # increment time for easier sorting
            curr_trans.time = prev_trans.time + 1
          end
        end

      end
      transactions << prev_trans unless (!insert_prev || (prev_trans == transactions.last))
      prev_trans = curr_trans unless not_valid
    end

    transactions << prev_trans unless not_valid
    return transactions
  end

end
