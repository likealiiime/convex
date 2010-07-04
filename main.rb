require 'cgi'
require 'net/http'
require 'uri'
require 'pp'

CALAIS_API_KEY = '88ebwmfczyk8fyra8b9wspyp'

CONTENT = <<TEXT
There is almost nothing more magical than a spectacular fireworks show – and now is the perfect time to let those sparklers in the sky serve as inspiration for your fingertips.
While some people–like the fabulous girls at WAH Nails (http://wah-nails.com/) in London–know how to get their nails properly did, many of us opt for simple petal-pink or deep red manis. Break out of your boring nail routine by adding a bit of sparkle to your hands via light-catching nail polish and blinding bling.

For something really outrageous, slip on Bijules gold nail rings (http://styledon.com/products/bijules/647-gold-nail-ring) (shown above left). Capping your nails in gold and securing them with a sexy serpent, these bad boys go for $160 a pop. For a less expensive gilded option, go with Chanel's Illusion D'Or (http://styledon.com/products/chanel/1387-illusion-dor) - I tried it the other day at Jin Soon Salon & Spa and it's gorgeous!! Play with this one as a French cap or use it to make a sparkling strip over another, brighter color. Bring more attention to hand with Iosselliani's gold and rhinestone ring, $312.

If you've never tried Deborah Lippmann nail products, you simply must. Her Smooth Operator buffer, $12, is the best we've ever used ever and her polishes brush on beautifully. Get the party started with glittery HAPPY BIRTHDAY and Marquee Moon lacquers, $16-18.

We introduced you to DANNIJO jewels earlier this year and now we're obsessed with their Aris ring, $215, which covers two fingers due to its three crystal clutters. Want the bang for less buck? Try the blue cocktail ring above for $65.If you can, we highly suggest adding bling to your bare hands in the form of killer Dior Fine Jewelry. As you can see via the skull and 'Oui' solitaire rings above and the pavé garden ring below, Dior Fine Jewelry is simply beyond. Love the look, but not in the position to make a purchase? Slip on Juicy Couture's Floral Cluster Ring, $88, instead. Shown above, far right, this ring is a bright bouquet of girly fun on your finger.

Sephora by OPI is always a reliable source for fun, crazy colors - Midnight Mambo and Teal We Meet Again, $9, are hitting the spot for us today. Vibrant, young and fun, we can't get enough of them.


Honestly, not much can rival the 'wow' factor of Minx nails, and now Sephora by OPI has teamed up with Minx to bring us a line called Chic Prints for Nails, you can do the mad manis in the comfort of your own home for $15 a pack.

For a vivid color that dries faster than a small fireworks fountain, reach for a bottle of Sally Hansen Insta-Dri in Pronto Purple. At just $3 a bottle, you now have no reason to show up to a party this weekend with bare nails. Rather go platinum? Pick up a bottle of Zoya in Trixie, $7. Of course, you could always look be inspired by WAH and nail it with heavy rhinestone coverage, a la the picture seen above, far right.

Looking for more great costume jewelry? Shop a ton of big blingy rings here...
TEXT

PARAMS = <<XML
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

DEBUGGING = false

class CalaisRequester
  # headers 'Accept-encoding' => 'gzip'
  
  def self.analyze(content)
    escaped_content = CGI.escape(content)
    uri = uri_for content
    post = Net::HTTP::Post.new('/enlighten/rest')
    post.initialize_http_header({
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Content-Length' => escaped_content.length.to_s
    })
    post.body = uri.query
    http = Net::HTTP.new(uri.host, uri.port)
    started = Time.now
    response = http.request(post)
    ended = Time.now
    puts "Took #{ended - started}s" if DEBUGGING
    return response
  end
  
  private
  
  def self.uri_for(content)
    uri = URI.parse('http://api.opencalais.com')
    uri.query = {
      :licenseID  => CGI.escape(CALAIS_API_KEY),
      :content    => CGI.escape(content),
      :paramsXML  => CGI.escape(PARAMS)
    }.collect { |key, value|
      "#{key}=#{value}"
    }.join('&')
    return uri
  end
end

puts "Ready."  if DEBUGGING
response = CalaisRequester.analyze CONTENT
puts response.body
