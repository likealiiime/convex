module Convex
  class Engine
    attr_reader :db, :trash, :response, :context, :code

    def initialize
      @code = Convex.next_engine_code
      debug "Hello, world!"
      @db = Redis.new
      debug "Connected to Redis"
      @db.select Convex.env.code
      debug "Selected #{Convex.env.stage} environment, code #{Convex.env.code}"
      reset!
    end
    
    def reset!
      @trash = Nokogiri::XML::Document.new
      @trash.root = Nokogiri::XML::Node.new('trash', trash)
      @response = NilEcho
      @context = []
      debug "Reset"
    end
    
    def debug(message)
      Convex.debug("Engine #{code}: " << message.to_s)
    end
  
    def focus!(text)
      reset!
      # Send to Calais
      text = text.to_s
      # Receive XML
      @response = Nokogiri.XML(DATA)
    end
  
    def debug_count
      debug "#{context.count} datum in context, #{@response.xpath('//*').count} nodes left"
    end
  
    def focus_from_xml!(xml)
      reset!
      debug "Focusing..."
      @response = Nokogiri.XML(xml)
      debug_count
      
      remove_response_headers
      filter_doc_cats
      filter_social_tags
      filter_subjects
      #filter_relevances
      filter_amounts_from_currencies
      filter_domains_from_urls
      
      debug "...Done Focusing!"
    end
    
    def each_datum_and_instance_info_node
      response.xpath('/rdf:RDF/rdf:Description[c:docId and rdf:type and c:subject]').each do |node|
        datum = Datum[node.xpath('./c:subject')[0]['resource'].to_s]
        yield datum, node
      end
    end
    
    private

    def remove_response_headers
      debug "Removing headers..."
      headers = response.xpath('/rdf:RDF/rdf:Description[@c:calaisRequestID and @c:id]') |
                response.xpath('/rdf:RDF/rdf:Description[@c:emVer]') |
                response.xpath('/rdf:RDF/rdf:Description[contains(@rdf:about, "DefaultLangId")]')
      headers.each { |node| node.parent = trash.root }
      debug_count
    end
    
    def filter_doc_cats
      debug "Filtering... DocCats"
      response.xpath('/rdf:RDF/rdf:Description[c:category]').each do |node|
        Convex::DatumType.remember('DocCat', node.xpath('./rdf:type')[0]['resource'])
        context << Datum.new({
          :value => node.xpath('./c:categoryName')[0].inner_text.to_s,
          :type => Convex::DatumType::DocCat,
          :weight => node.xpath('./c:score')[0].inner_text.to_f,
          :calais_ref_uri => node.xpath('./c:category')[0]['resource'].to_s
        }).remember
        node.parent = trash.root
      end
      debug_count
    end
    
    def filter_social_tags
      response.xpath('/rdf:RDF/rdf:Description[c:socialtag]').each do |node|
        Convex::DatumType.remember('SocialTag', node.xpath('./rdf:type')[0]['resource'])
        importance = node.xpath('./c:importance')[0].inner_text.to_f || 100.0
        context << Datum.new({
          :value => node.xpath('./c:name')[0].inner_text.to_s,
          :type => Convex::DatumType::SocialTag,
          :calais_ref_uri => node.xpath('./c:socialtag')[0]['resource'].to_s,
          :weight => 1.0 / importance
        }).remember
        node.parent = trash.root
      end
      debug "Filtered SocialTags"
      debug_count
    end
    
    def filter_subjects
      debug "Filtering Entities..."
      # <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2">
      #  <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Currency"/>
      #  <c:name>USD</c:name>
      # </rdf:Description>
      #
      # Subjects only occur once, and c:name is bound to rdf:Description@rdf:about.
      # Subjects indicate what the other InstanceInfo refer to
      response.xpath('/rdf:RDF/rdf:Description[c:name and rdf:type]').each do |node|
        uri = node.xpath('./rdf:type')[0]['resource'].to_s
        next if uri.empty?
        datum = Datum.new({
          :value => node.xpath('./c:name')[0].inner_text.to_s,
          :type => Convex::DatumType.remember(uri.split('/').last, uri),
          :calais_ref_uri => node['about']
        }).remember
        context << datum if datum.type.name == 'URL'
        node.parent = trash.root
      end
      debug_count
    end
    
    def filter_relevances
      debug "Filtering Relevances..."
      each_datum_and_instance_info_node do |datum, node|
        relevance_node = node.xpath('./c:relevance')[0]
        unless relevance_node.nil?
          # Update weights of entity types
          datum.weight = relevance_node.inner_text.to_f
          node.parent = trash.root
        end
      end
      debug_count
    end
    
    def filter_amounts_from_currencies
      debug "Filtering amounts from currencies..."
      uris = Datum[Convex::DatumType::Currency].collect { |d| d.calais_ref_uri }.join(',')
      #require 'ruby-debug/debugger'
      response.xpath("/rdf:RDF/rdf:Description[c:exact and c:subject and contains(\"#{uris}\", c:subject/@rdf:resource)]").each do |node|
        # Enter data as Currency sub-types. Ex - USD
        uri = node.xpath('./c:subject')[0]['resource'].to_s
        datum = Datum[uri]
        amount = node.xpath('./c:exact')[0].inner_text.gsub(/[^\d\.]/,'').to_f
        context << Datum.new({
          :value => amount,
          :type => Convex::DatumType.remember(datum.value, datum.calais_ref_uri)
        }).remember
        node.parent = trash.root
      end
      debug_count
    end
      
    def filter_domains_from_urls
      debug "Filtering domains from URLs..."
      context.select { |d| d.type == Convex::DatumType::URL }.each do |datum|
        # Enter URL domains as separate datum
        uri = URI.parse(datum.value)
        context << Datum.new({
          :value => uri.host,
          :type => Convex::DatumType::URLDomain,
          :weight => datum.weight
        }) if uri.is_a? URI::HTTP
      end
      debug_count
    end
    
  end
end