module ClassMethods
  # any method placed here will apply to classes


  def acts_as_cities(options = {})

    # Option for setting the inheritance columns, default value = 'type'
    db_type_field = (options[:db_type_field] || :type).to_s

    #:table_name = option for setting the name of the current class table_name, default value = 'tableized(current class name)'
    table_name = (options[:table_name] || self.name.tableize.gsub(/\//,'_')).to_s

    set_inheritance_column "#{db_type_field}"

    if(self.superclass!=ActiveRecord::Base)
      # Non mother-class

      cities_debug("Non Mother Class")
      cities_debug("table_name -> #{table_name}")
      
      # Set up the table which contains ALL attributes we want for this class
      set_table_name "view_#{table_name}"

      cities_debug("tablename (view) -> #{self.table_name}")

      # The the Clone. References the write-able table for the class because
      # save operations etc can't take place on the views
      self.const_set("Clone", create_class_clone(self))

      # Add the functions required for children only
      send :include, ChildInstanceMethods
    else
      # Mother class

      after_save :updatetype

      cities_debug("Mother Class")
      
      set_table_name "#{table_name}"
      
      cities_debug("table_name -> #{self.table_name}")

      def self.mother_class #returns the mother class (the highest inherited class before ActiveRecord) 
        if(self.superclass!=ActiveRecord::Base)  
          self.superclass.mother_class
        else
          return self 
        end
      end

      def self.find(*args) #overrides find to get all attributes  

        tuples = super

        # in case of several tuples just return the tuples as they are
        return tuples if tuples.kind_of?(Array)

        # in case of only one tuple, return a reloaded tuple based on the class of this tuple
        tuples.class.where(tuples.class[:id].eq(tuples.id))[0]

        #Was something about reload2 here as well but seems to work fine...?                                                       
      end

      # Unlike destroy_all it is useful to override this method.
      # In fact destroy_all will explicitly call a destroy method on each object
      # whereas delete_all doesn't and only calls specific SQL requests.
      # To be even more precise call delete_all with special conditions
      def self.delete_all
        #call delete method for each instance of the class
        self.all.each{|o| o.delete }
      end

      # Add the functions required for mother classes only
      send :include, MotherInstanceMethods
    end



  end

end  