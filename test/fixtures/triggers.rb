trigger :model => 'Item', :before => [:insert, :update], :implementation => <<-sql
  SET NEW.updated_at = NOW();
sql

trigger :table_name => 'items', :after => :insert, :implementation => <<-sql
  UPDATE carts SET updated_at = NOW() WHERE id = NEW.cart_id;
sql

trigger :table_name => 'items', :after => :update, :implementation => <<-sql
  UPDATE carts SET updated_at = NOW() WHERE id IN (OLD.cart_id, NEW.cart_id);
sql

trigger :table_name => 'items', :after => :delete, :implementation => <<-sql
  UPDATE carts SET updated_at = NOW() WHERE id = OLD.cart_id;
sql
