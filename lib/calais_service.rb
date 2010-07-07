require 'cgi'
require 'net/http'
require 'uri'

module Convex
  class CalaisService
    include Convex::CustomizedLogging
    
    API_KEY = '88ebwmfczyk8fyra8b9wspyp'
    
    PARAMS = <<-XML
    <c:params xmlns:c="http://s.opencalais.com/1/pred/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <c:processingDirectives
          c:contentType="text/raw"
          c:outputFormat="xml/rdf"
          c:enableMetadataType="SocialTags"
          c:calculateRelevanceScore="true"
          c:docRDFaccessible="true"
          c:omitOutputtingOriginalText="true"/>
      <c:userDirectives
          c:allowDistribution="true"
          c:allowSearch="true"
          c:submitter="styledon"/>
      <c:externalMetadata/>
    </c:params>
    XML
    
    # headers 'Accept-encoding' => 'gzip'
  
    def log_preamble; "CalaisService"; end
    
    def analyze(content)
      escaped_content = CGI.escape(content)
      uri = uri_for content
      post = Net::HTTP::Post.new('/enlighten/rest')
      post.initialize_http_header({
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Content-Length' => escaped_content.length.to_s
      })
      post.body = uri.query
      http = Net::HTTP.new(uri.host, uri.port)
      debug "Beginning request of %.1fKB" % (escaped_content.length.to_f / 1024.0)
      started = Time.now
      response = http.request(post)
      ended = Time.now
      info "Took %.2fs" % (ended - started)
      log_newline
      return response.body
    end
  
    private
  
    def uri_for(content)
      uri = URI.parse('http://api.opencalais.com')
      uri.query = {
        :licenseID  => CGI.escape(API_KEY),
        :content    => CGI.escape(content),
        :paramsXML  => CGI.escape(PARAMS)
      }.collect { |key, value|
        "#{key}=#{value}"
      }.join('&')
      return uri
    end
  end
end