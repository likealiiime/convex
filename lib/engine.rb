module Convex
  class Engine
    include Convex::CustomizedLogging
    
    attr_reader   :db, :trash, :response, :context, :code
    attr_reader   :subject_uri_index, :calais_ref_uri_index, :datum_type_index
    attr_accessor :lenses

    def initialize
      @code = Convex.next_engine_code
      info "Hello, world!"
      @db = Redis.new
      debug "Connected to Redis"
      @db.select Convex.env.code
      debug "SELECTed #{Convex.env.mode} database, code #{Convex.env.code}"
      @calais = Convex::CalaisService.new
      reset!
    end
    
    def reset!
      @trash = Nokogiri::XML::Document.new
      @trash.root = Nokogiri::XML::Node.new('trash', trash)
      @response = NilEcho
      @context = []
      @subject_uri_index = {}
      @calais_ref_uri_index = {}
      @datum_type_index = {}
    end
    
    def inspect; "Engine #{code}"; end
    alias_method :to_s, :inspect
    alias_method :log_preamble, :inspect
    
    def focus!(text)
      reset!
      focus_using_xml(@calais.analyze(text))
    end
  
    def debug_count
      debug "#{context.count} datum in context, #{@response.xpath('//*').count} nodes left"
    end
  
    def focus_using_xml(xml)
      xml = xml.to_s
      info "Focusing %.1fKB of XML..." % (xml.length.to_f / 1024.0)
      @response = Nokogiri.XML(xml)
      debug_count
      
      remove_response_headers
      filter_doc_cats
      filter_social_tags
      filter_subjects
      filter_relevances
      filter_amounts_from_currencies if Convex::DatumType.knows? 'Currency'
      filter_domains_from_urls if Convex::DatumType.knows? 'URL'
      
      info "...Done Focusing! Sending to Lenses..."
      Convex.lenses.each { |lens| lens.focus_using_data!(context, self) }
      return context
    rescue Exception => e
      error "Exception caught: #{e.inspect} in #{e.backtrace.first}"
      error "Focusing has been abandoned with #{context.count} datum in context, #{@response.xpath('//*').count} nodes left"
      debug e.backtrace.join("\n")
      return context
    end
    
    private

    def new_and_indexed_datum(config)
      datum = Datum.new(config)
      @datum_type_index[datum.type] ||= []
      @datum_type_index[datum.type] << datum
      return datum
    end
    
    def remove_response_headers
      log_newline
      debug "Removing headers..."
      headers = response.xpath('/rdf:RDF/rdf:Description[@c:calaisRequestID and @c:id]') |
                response.xpath('/rdf:RDF/rdf:Description[@c:emVer]') |
                response.xpath('/rdf:RDF/rdf:Description[contains(@rdf:about, "DefaultLangId")]')
      headers.each { |node| node.parent = trash.root }
      debug_count
    end
    
    def filter_doc_cats
      log_newline
      debug "Filtering DocCats..."
      response.xpath('/rdf:RDF/rdf:Description[c:category]').each do |node|
        Convex::DatumType.remember('DocCat', node.xpath('./rdf:type')[0]['resource'])
        context << new_and_indexed_datum({
          :value => node.xpath('./c:categoryName')[0].inner_text.to_s,
          :type => Convex::DatumType::DocCat,
          :weight => node.xpath('./c:score')[0].inner_text.to_f,
          :calais_ref_uri => node.xpath('./c:category')[0]['resource'].to_s
        })
        node.parent = trash.root
      end
      debug_count
    end
    
    def filter_social_tags
      log_newline
      debug "Filtering SocialTags..."
      response.xpath('/rdf:RDF/rdf:Description[c:socialtag]').each do |node|
        Convex::DatumType.remember('SocialTag', node.xpath('./rdf:type')[0]['resource'])
        importance = node.xpath('./c:importance')[0].inner_text.to_f || 100.0
        context << new_and_indexed_datum({
          :value => node.xpath('./c:name')[0].inner_text.to_s,
          :type => Convex::DatumType::SocialTag,
          :calais_ref_uri => node.xpath('./c:socialtag')[0]['resource'].to_s,
          :weight => 1.0 / importance
        })
        node.parent = trash.root
      end
      debug_count
    end
    
    def filter_subjects
      log_newline
      debug "Filtering Subjects..."
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
        datum = new_and_indexed_datum({
          :value => node.xpath('./c:name')[0].inner_text.to_s,
          :type => Convex::DatumType.remember(uri.split('/').last, uri),
          :calais_ref_uri => node['about']
        })
        # URLs are a subject that also count as contextual data
        context << datum if datum.type.name == 'URL'
        subject_uri_index[node['about']] = datum if node['about']
        node.parent = trash.root
      end
      debug_count
    end
    
    def filter_relevances
      log_newline
      debug "Filtering Relevances..."
      response.xpath("/rdf:RDF/rdf:Description[c:subject and c:relevance]").each do |node|
        relevance_node = node.xpath('./c:relevance')[0]
        subject_uri = node.xpath('./c:subject')[0]['resource'].to_s        
        unless relevance_node.nil? || subject_uri.empty?
          # Update weights of entity types
          datum = subject_uri_index[subject_uri]
          datum.weight = relevance_node.inner_text.to_f
          debug "#{datum.value} now weighs #{datum.weight}"
          node.parent = trash.root
        end
      end
      debug_count
    end
    
    def filter_amounts_from_currencies
      log_newline
      debug "Filtering amounts from currencies..."
      uris = @datum_type_index[Convex::DatumType::Currency].collect { |d| d.calais_ref_uri }.join(',')
      response.xpath("/rdf:RDF/rdf:Description[c:exact and c:subject and contains(\"#{uris}\", c:subject/@rdf:resource)]").each do |node|
        # Enter data as Currency sub-types. Ex - USD
        subject_uri = node.xpath('./c:subject')[0]['resource'].to_s
        datum = @subject_uri_index[subject_uri]
        amount = node.xpath('./c:exact')[0].inner_text.gsub(/[^\d\.]/,'').to_f
        context << new_and_indexed_datum({
          :value => amount,
          :type => Convex::DatumType.remember(datum.value, datum.calais_ref_uri)
        })
        node.parent = trash.root
      end
      debug_count
    end
      
    def filter_domains_from_urls
      log_newline
      debug "Filtering domains from URLs..."
      context.select { |d| d.type == Convex::DatumType::URL }.each do |datum|
        # Enter URL domains as separate datum
        uri = URI.parse(datum.value)
        context << new_and_indexed_datum({
          :value => uri.host,
          :type => Convex::DatumType::CXURLDomain,
          :weight => datum.weight
        }) if uri.is_a? URI::HTTP
      end
      debug_count
    end
    
  end
end