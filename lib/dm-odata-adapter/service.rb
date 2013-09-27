module Odata
  class Service < OData::Service
    attr_accessor :registery
    
    # Converts an XML Entry into a class
     def entry_to_class(entry)
       # Retrieve the class name from the fully qualified name (the last string after the last dot)
       klass_name = entry.xpath("./atom:category/@term", @ds_namespaces).to_s.split('.')[-1]

       # Is the category missing? See if there is a title that we can use to build the class
       if klass_name.nil?
         title = entry.xpath("./atom:title", @ds_namespaces).first
         return nil if title.nil?
         klass_name = title.content.to_s
       end

       return nil if klass_name.nil?

       properties = entry.xpath("./atom:content/m:properties/*", @ds_namespaces)

       klass = @classes[qualify_class_name(klass_name)].new

       # Fill metadata
       meta_id = entry.xpath("./atom:id", @ds_namespaces)[0].content
       klass.send :__metadata=, { :uri => meta_id } if klass.respond_to? :__metadata=

       dm_properties = @registery.fetch(klass_name.to_s)
       DataMapper.logger.debug("dm_properties for class #{klass_name} are #{dm_properties.inspect}")
       
       # Fill properties
       for prop in properties
         prop_name = prop.name
         value = parse_value_xml(prop)
         DataMapper.logger.debug("prop_name #{prop_name}")
         mapped_name = dm_properties.fetch(prop_name).name
         DataMapper.logger.debug( "setting #{mapped_name} to #{value}")
         klass.send("#{mapped_name}=", value)
       end

       # Fill properties represented outside of the properties collection
       @class_metadata[qualify_class_name(klass_name)].select { |k,v| v.fc_keep_in_content == false }.each do |k, meta|
         if meta.fc_target_path == "SyndicationTitle"
           title = entry.xpath("./atom:title", @ds_namespaces).first
           klass.send "#{meta.name}=", title.content
         elsif meta.fc_target_path == "SyndicationSummary"
           summary = entry.xpath("./atom:summary", @ds_namespaces).first
           klass.send "#{meta.name}=", summary.content
         end
       end

       inline_links = entry.xpath("./atom:link[m:inline]", @ds_namespaces)

       for link in inline_links
         # TODO: Use the metadata's associations to determine the multiplicity instead of this "hack"
         property_name = link.attributes['title'].to_s
         if singular?(property_name)
           inline_entry = link.xpath("./m:inline/atom:entry", @ds_namespaces).first
           inline_klass = build_inline_class(klass, inline_entry, property_name)
           klass.send "#{property_name}=", inline_klass
         else
           inline_classes, inline_entries = [], link.xpath("./m:inline/atom:feed/atom:entry", @ds_namespaces)
           for inline_entry in inline_entries
             # Build the class
             inline_klass = entry_to_class(inline_entry)

             # Add the property to the temp collection
             inline_classes << inline_klass
           end

           # Assign the array of classes to the property
           property_name = link.xpath("@title", @ds_namespaces)
           klass.send "#{property_name}=", inline_classes
         end
       end

       klass
     end
     
  end
end