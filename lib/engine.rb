module Convex
  class Engine
    include Convex::CustomizedLogging
    
    attr_reader   :db, :trash, :response, :context, :code, :subject_uri_index
    attr_accessor :lenses

    def initialize
      @code = Convex.next_engine_code
      info "Hello, world!"
      @db = Redis.new
      debug "Connected to Redis"
      @db.select Convex.env.code
      debug "SELECTed #{Convex.env.mode} database, code #{Convex.env.code}"
      @calais = Convex::CalaisService.new
      @lenses = []
      reset!
    end
    
    def reset!
      @trash = Nokogiri::XML::Document.new
      @trash.root = Nokogiri::XML::Node.new('trash', trash)
      @response = NilEcho
      @context = []
      @subject_uri_index = {}
      debug "Reset"
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
      filter_amounts_from_currencies
      filter_domains_from_urls
      
      info "...Done Focusing! Sending to Lenses..."
      Convex.lenses.each { |lens| lens.focus_using_data!(context, self) }
    end
    
    private

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
      log_newline
      debug "Filtering SocialTags..."
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
        datum = Datum.new({
          :value => node.xpath('./c:name')[0].inner_text.to_s,
          :type => Convex::DatumType.remember(uri.split('/').last, uri),
          :calais_ref_uri => node['about']
        }).remember
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
        uri = node.xpath('./c:subject')[0]['resource'].to_s        
        unless relevance_node.nil? || uri.empty?
          # Update weights of entity types
          datum = subject_uri_index[uri]
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
      uris = Datum[Convex::DatumType::Currency].collect { |d| d.calais_ref_uri }.join(',')
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
      log_newline
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