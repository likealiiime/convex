require 'convex_application'

Convex = ConvexApplication.new :development
Convex.boot!

xml = Nokogiri.XML(DATA)
trash = Nokogiri::XML::Document.new
trash.root = Nokogiri::XML::Node.new('trash', trash)

puts "\nBefore header info, there are #{xml.xpath('//*').count} nodes"
headers = xml.xpath('/rdf:RDF/rdf:Description[@c:calaisRequestID and @c:id]') |
          xml.xpath('/rdf:RDF/rdf:Description[@c:emVer]') |
          xml.xpath('/rdf:RDF/rdf:Description[contains(@rdf:about, "DefaultLangId")]')
headers.each { |node| node.parent = trash.root }

puts "\nBefore SocialTags, there are #{xml.xpath('//*').count} nodes"
social_tags = []
xml.xpath('/rdf:RDF/rdf:Description[c:socialtag]').each do |node|
  DatumType.remember('SocialTag', node.xpath('./rdf:type')[0]['resource'])
  importance = node.xpath('./c:importance')[0].inner_text.to_f || 100.0
  social_tags << Datum.new({
    :value => node.xpath('./c:name')[0].inner_text.to_s,
    :type => DatumType::SocialTag,
    :calais_ref_uri => node.xpath('./c:socialtag')[0]['resource'].to_s,
    :weight => 1.0 / importance
  })
  node.parent = trash.root
end
pp social_tags

puts "\nBefore DocCats, there are #{xml.xpath('//*').count} nodes"
doc_cats = []
xml.xpath('/rdf:RDF/rdf:Description[c:category]').each do |node|
  DatumType.remember('DocCat', node.xpath('./rdf:type')[0]['resource'])
  doc_cats << Datum.new({
    :value => node.xpath('./c:categoryName')[0].inner_text.to_s,
    :type => DatumType::DocCat,
    :weight => node.xpath('./c:score')[0].inner_text.to_f,
    :calais_ref_uri => node.xpath('./c:category')[0]['resource'].to_s
  })
  node.parent = trash.root
end
pp doc_cats

puts "\nBefore entity types, there are #{xml.xpath('//*').count} nodes"
entity_types = []
xml.xpath('/rdf:RDF/rdf:Description[c:name and rdf:type]').each do |node|
  uri = node.xpath('./rdf:type')[0]['resource'].to_s
  next if uri.empty?
  t = DatumType.remember(uri.split('/').last, uri)
  entity_types << Datum.new({
    :value => node.xpath('./c:name')[0].inner_text.to_s,
    :type => t,
    :calais_ref_uri => node['about']
  })
  node.parent = trash.root
end

puts "\nBefore entity details there are #{xml.xpath('//*').count} nodes"
details = []
xml.xpath('/rdf:RDF/rdf:Description[c:docId and rdf:type and c:subject]').each do |node|
  datum = Datum[node.xpath('./c:subject')[0]['resource'].to_s]
  
  if datum.type == DatumType::Currency
    # Enter data as Currency sub-types
    subtype = DatumType.remember(datum.value, datum.calais_ref_uri)
    amount = node.xpath('./c:exact')[0]
    details << Datum.new({
      :value => amount.inner_text.gsub(/[^\d\.]/,'').to_f,
      :type => subtype
    })
    node.parent = trash.root
  elsif !(relevance = node.xpath('./c:relevance')[0]).nil?
    # Update weights of entity types
    uri = node.xpath('./c:subject')[0]['resource'].to_s
    datum.weight = relevance.inner_text.to_f
    node.parent = trash.root
  end
end

Datum[DatumType::URL].each do |datum|
  # Enter URL domains as separate datum
  uri = URI.parse(datum.value)
  details << Datum.new({
    :value => uri.host,
    :type => DatumType::URLDomain,
    :weight => datum.weight
  }) if uri.is_a? URI::HTTP
end

pp entity_types
puts
pp details

puts "\nThere are #{xml.xpath('//*').count} nodes remaining"
#require 'ruby-debug/debugger'

__END__
<?xml version="1.0"?>
<!--Use of the Calais Web Service is governed by the Terms of Service located at http://www.opencalais.com. By using this service or the results of the service you agree to these terms of service.-->
<!--Relations: 

City: London
Currency: USD
IndustryTerm: nail products
Person: Deborah Lippmann, Dior Fine Jewelry, Jin Soon Salon, Sally Hansen Insta-Dri
URL: http://styledon.com/products/bijules/647-gold-nail-ring, http://styledon.com/products/chanel/1387-illusion-dor, http://wah-nails.com-->
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:c="http://s.opencalais.com/1/pred/">
  <rdf:Description c:allowDistribution="true" c:allowSearch="true" c:calaisRequestID="39421090-d6cf-ed41-2999-b69b656be6f4" c:docRDFaccessible="true" c:id="http://id.opencalais.com/OXuXKxZTmrnpIBd8aYHTlQ" rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/DocInfo"/>
    <c:document/>
    <c:docTitle/>
    <c:docDate>2010-07-03 14:09:28.934</c:docDate>
    <c:externalMetadata/>
    <c:submitter>styledon</c:submitter>
  </rdf:Description>
  <rdf:Description c:contentType="text/raw" c:emVer="7.1.1103.5" c:langIdVer="DefaultLangId" c:language="English" c:processingVer="CalaisJob01" c:stagsVer="1.0.0-b1-2009-11-12_16:54:24" c:submissionDate="2010-07-03 14:09:28.293" rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/meta">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/DocInfoMeta"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:submitterCode>36ab4b83-e728-bfa7-b38c-9e2a72225531</c:submitterCode>
    <c:signature>digestalg-1|hm2QwImC1pmYVjEiZbxCt6PgXEE=|L4L5hMweZ6apVJewJMFRr9VvoiSMC/6iiqVW7gd4N4EMFGz1Mdes+A==</c:signature>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/lid/DefaultLangId">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/lid/DefaultLangId"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:lang rdf:resource="http://d.opencalais.com/lid/DefaultLangId/English"/>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/1">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/44ea1851-0ff8-3074-971e-33864c95abfa"/>
    <c:name>Cosmetics</c:name>
    <c:importance>1</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/2">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/0b3c5057-0236-308e-b665-4cbc14a7ecd8"/>
    <c:name>Rings</c:name>
    <c:importance>1</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/3">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/d7e85d55-9111-311d-8bbb-4432b9997ead"/>
    <c:name>Fashion</c:name>
    <c:importance>1</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/4">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/17f757ac-3e17-3efb-b04b-bde3f75a7fbf"/>
    <c:name>Linguistics</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/5">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/c7e69392-3647-3ee8-8855-e5c77e538de5"/>
    <c:name>Clothing</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/6">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/702485a2-30ce-3236-a785-b1b5141b3aa7"/>
    <c:name>Fasteners</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/7">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/1a20cbf7-0cf8-35d9-9673-46c1e1c4b97c"/>
    <c:name>Woodworking</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/8">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/1aa20701-c146-3ac9-8bca-b52dbe805d45"/>
    <c:name>Toiletry</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/9">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/46c7b99f-85bf-3efe-9584-7dee490661f4"/>
    <c:name>Nail polish</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/10">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/d5a3c111-4364-3355-89d7-cdf86344b236"/>
    <c:name>Nail</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/11">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/6059f6c0-0cc3-3d67-bb9d-2084c46267cf"/>
    <c:name>Bling-bling</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/SocialTag/12">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/tag/SocialTag"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:socialtag rdf:resource="http://d.opencalais.com/genericHasher-1/82e5fcf4-3fea-300f-827a-f251a8e626b0"/>
    <c:name>Zoya</c:name>
    <c:importance>2</c:importance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/cat/1">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/cat/DocCat"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:category rdf:resource="http://d.opencalais.com/cat/Calais/Other"/>
    <c:classifierName>Calais</c:classifierName>
    <c:categoryName>Other</c:categoryName>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/49634b11-55d9-3f10-9511-3a87e4536d29">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/IndustryTerm"/>
    <c:name>nail products</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/1">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/49634b11-55d9-3f10-9511-3a87e4536d29"/>
    <!--IndustryTerm: nail products; -->
    <c:detection>[$312.

If you've never tried Deborah Lippmann ]nail products[, you simply must. Her Smooth Operator buffer,]</c:detection>
    <c:prefix>$312.

If you've never tried Deborah Lippmann </c:prefix>
    <c:exact>nail products</c:exact>
    <c:suffix>, you simply must. Her Smooth Operator buffer,</c:suffix>
    <c:offset>1153</c:offset>
    <c:length>13</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/1">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/49634b11-55d9-3f10-9511-3a87e4536d29"/>
    <c:relevance>0.267</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/pershash-1/ead97367-296e-3ab0-9891-fde4e91f8c79">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Person"/>
    <c:name>Deborah Lippmann</c:name>
    <c:persontype>N/A</c:persontype>
    <c:nationality>N/A</c:nationality>
    <c:commonname>Deborah Lippmann</c:commonname>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/2">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/ead97367-296e-3ab0-9891-fde4e91f8c79"/>
    <!--Person: Deborah Lippmann; -->
    <c:detection>[rhinestone ring, $312.

If you've never tried ]Deborah Lippmann[ nail products, you simply must. Her Smooth]</c:detection>
    <c:prefix>rhinestone ring, $312.

If you've never tried </c:prefix>
    <c:exact>Deborah Lippmann</c:exact>
    <c:suffix> nail products, you simply must. Her Smooth</c:suffix>
    <c:offset>1136</c:offset>
    <c:length>16</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/3">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/ead97367-296e-3ab0-9891-fde4e91f8c79"/>
    <!--Person: Deborah Lippmann; -->
    <c:detection>[ Deborah Lippmann nail products, you simply must. ]Her[ Smooth Operator buffer, $12, is the best we've]</c:detection>
    <c:prefix> Deborah Lippmann nail products, you simply must. </c:prefix>
    <c:exact>Her</c:exact>
    <c:suffix> Smooth Operator buffer, $12, is the best we've</c:suffix>
    <c:offset>1185</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/4">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/ead97367-296e-3ab0-9891-fde4e91f8c79"/>
    <!--Person: Deborah Lippmann; -->
    <c:detection>[$12, is the best we've ever used ever and ]her[ polishes brush on beautifully. Get the party]</c:detection>
    <c:prefix>$12, is the best we've ever used ever and </c:prefix>
    <c:exact>her</c:exact>
    <c:suffix> polishes brush on beautifully. Get the party</c:suffix>
    <c:offset>1255</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/2">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/ead97367-296e-3ab0-9891-fde4e91f8c79"/>
    <c:relevance>0.300</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/pershash-1/507b7085-72f0-32c9-8d4f-3ec1b2c5f713">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Person"/>
    <c:name>Sally Hansen Insta-Dri</c:name>
    <c:persontype>N/A</c:persontype>
    <c:nationality>N/A</c:nationality>
    <c:commonname>Sally Hansen Insta-Dri</c:commonname>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/5">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/507b7085-72f0-32c9-8d4f-3ec1b2c5f713"/>
    <!--Person: Sally Hansen Insta-Dri; -->
    <c:detection>[small fireworks fountain, reach for a bottle of ]Sally Hansen Insta-Dri[ in Pronto Purple. At just $3 a bottle, you now]</c:detection>
    <c:prefix>small fireworks fountain, reach for a bottle of </c:prefix>
    <c:exact>Sally Hansen Insta-Dri</c:exact>
    <c:suffix> in Pronto Purple. At just $3 a bottle, you now</c:suffix>
    <c:offset>2568</c:offset>
    <c:length>22</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/3">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/507b7085-72f0-32c9-8d4f-3ec1b2c5f713"/>
    <c:relevance>0.078</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/e364856e-21a6-3b6a-957d-0849a55a4d5e">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/URL"/>
    <c:name>http://styledon.com/products/bijules/647-gold-nail-ring</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/6">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/e364856e-21a6-3b6a-957d-0849a55a4d5e"/>
    <!--URL: http://styledon.com/products/bijules/647-gold-nail-ring; -->
    <c:detection>[outrageous, slip on Bijules gold nail rings (]http://styledon.com/products/bijules/647-gold-nail-ring[) (shown above left). Capping your nails in gold]</c:detection>
    <c:prefix>outrageous, slip on Bijules gold nail rings (</c:prefix>
    <c:exact>http://styledon.com/products/bijules/647-gold-nail-ring</c:exact>
    <c:suffix>) (shown above left). Capping your nails in gold</c:suffix>
    <c:offset>561</c:offset>
    <c:length>55</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/4">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/e364856e-21a6-3b6a-957d-0849a55a4d5e"/>
    <c:relevance>0.320</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/4e62064e-69f4-39f9-b2f5-89b728197de3">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/URL"/>
    <c:name>http://styledon.com/products/chanel/1387-illusion-dor</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/7">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/4e62064e-69f4-39f9-b2f5-89b728197de3"/>
    <!--URL: http://styledon.com/products/chanel/1387-illusion-dor; -->
    <c:detection>[gilded option, go with Chanel's Illusion D'Or (]http://styledon.com/products/chanel/1387-illusion-dor[) - I tried it the other day at Jin Soon Salon &amp;]</c:detection>
    <c:prefix>gilded option, go with Chanel's Illusion D'Or (</c:prefix>
    <c:exact>http://styledon.com/products/chanel/1387-illusion-dor</c:exact>
    <c:suffix>) - I tried it the other day at Jin Soon Salon &amp;</c:suffix>
    <c:offset>806</c:offset>
    <c:length>53</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/5">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/4e62064e-69f4-39f9-b2f5-89b728197de3"/>
    <c:relevance>0.301</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/df61f880-c9f1-3295-8028-872a538df2a2">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/URL"/>
    <c:name>http://wah-nails.com</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/8">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/df61f880-c9f1-3295-8028-872a538df2a2"/>
    <!--URL: http://wah-nails.com; -->
    <c:detection>[people&#x2013;like the fabulous girls at WAH Nails (]http://wah-nails.com[/) in London&#x2013;know how to get their nails properly]</c:detection>
    <c:prefix>people&#x2013;like the fabulous girls at WAH Nails (</c:prefix>
    <c:exact>http://wah-nails.com</c:exact>
    <c:suffix>/) in London&#x2013;know how to get their nails properly</c:suffix>
    <c:offset>233</c:offset>
    <c:length>20</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/6">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/df61f880-c9f1-3295-8028-872a538df2a2"/>
    <c:relevance>0.322</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/er/geo/city/ralg-geo1/f08025f6-8e95-c3ff-2909-0a5219ed3bfa">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/er/Geo/City"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <!--London-->
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/6fda72fd-105c-39ba-bb79-da95785a249f"/>
    <c:name>London,Greater London,United Kingdom</c:name>
    <c:shortname>London</c:shortname>
    <c:containedbystate>Greater London</c:containedbystate>
    <c:containedbycountry>United Kingdom</c:containedbycountry>
    <c:latitude>51.517124</c:latitude>
    <c:longitude>-0.106196</c:longitude>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/pershash-1/354b70d4-1931-3943-8ddd-79517823a0a8">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Person"/>
    <c:name>Dior Fine Jewelry</c:name>
    <c:persontype>N/A</c:persontype>
    <c:nationality>N/A</c:nationality>
    <c:commonname>Dior Fine Jewelry</c:commonname>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/9">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/354b70d4-1931-3943-8ddd-79517823a0a8"/>
    <!--Person: Dior Fine Jewelry; -->
    <c:detection>[bling to your bare hands in the form of killer ]Dior Fine Jewelry[. As you can see via the skull and 'Oui']</c:detection>
    <c:prefix>bling to your bare hands in the form of killer </c:prefix>
    <c:exact>Dior Fine Jewelry</c:exact>
    <c:suffix>. As you can see via the skull and 'Oui'</c:suffix>
    <c:offset>1696</c:offset>
    <c:length>17</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/10">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/354b70d4-1931-3943-8ddd-79517823a0a8"/>
    <!--Person: Dior Fine Jewelry; -->
    <c:detection>[rings above and the pav&#xE9; garden ring below, ]Dior Fine Jewelry[ is simply beyond. Love the look, but not in the]</c:detection>
    <c:prefix>rings above and the pav&#xE9; garden ring below, </c:prefix>
    <c:exact>Dior Fine Jewelry</c:exact>
    <c:suffix> is simply beyond. Love the look, but not in the</c:suffix>
    <c:offset>1808</c:offset>
    <c:length>17</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/7">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/354b70d4-1931-3943-8ddd-79517823a0a8"/>
    <c:relevance>0.178</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/pershash-1/7e6510de-684f-346c-9f00-e66d54c0c0ba">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Person"/>
    <c:name>Jin Soon Salon</c:name>
    <c:persontype>N/A</c:persontype>
    <c:nationality>N/A</c:nationality>
    <c:commonname>Jin Soon Salon</c:commonname>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/11">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/7e6510de-684f-346c-9f00-e66d54c0c0ba"/>
    <!--Person: Jin Soon Salon; -->
    <c:detection>[- I tried it the other day at ]Jin Soon Salon[ &amp; Spa and it's gorgeous!! Play with this one as]</c:detection>
    <c:prefix>- I tried it the other day at </c:prefix>
    <c:exact>Jin Soon Salon</c:exact>
    <c:suffix> &amp; Spa and it's gorgeous!! Play with this one as</c:suffix>
    <c:offset>891</c:offset>
    <c:length>14</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/8">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/pershash-1/7e6510de-684f-346c-9f00-e66d54c0c0ba"/>
    <c:relevance>0.301</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/6fda72fd-105c-39ba-bb79-da95785a249f">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/City"/>
    <c:name>London</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/12">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/6fda72fd-105c-39ba-bb79-da95785a249f"/>
    <!--City: London; -->
    <c:detection>[girls at WAH Nails (http://wah-nails.com/) in ]London[&#x2013;know how to get their nails properly did, many]</c:detection>
    <c:prefix>girls at WAH Nails (http://wah-nails.com/) in </c:prefix>
    <c:exact>London</c:exact>
    <c:suffix>&#x2013;know how to get their nails properly did, many</c:suffix>
    <c:offset>259</c:offset>
    <c:length>6</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/9">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/6fda72fd-105c-39ba-bb79-da95785a249f"/>
    <c:relevance>0.322</c:relevance>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/em/e/Currency"/>
    <c:name>USD</c:name>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/13">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[them with a sexy serpent, these bad boys go for ]$160[ a pop. For a less expensive gilded option, go]</c:detection>
    <c:prefix>them with a sexy serpent, these bad boys go for </c:prefix>
    <c:exact>$160</c:exact>
    <c:suffix> a pop. For a less expensive gilded option, go</c:suffix>
    <c:offset>726</c:offset>
    <c:length>4</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/14">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[with Iosselliani's gold and rhinestone ring, ]$312[.

If you've never tried Deborah Lippmann nail]</c:detection>
    <c:prefix>with Iosselliani's gold and rhinestone ring, </c:prefix>
    <c:exact>$312</c:exact>
    <c:suffix>.

If you've never tried Deborah Lippmann nail</c:suffix>
    <c:offset>1107</c:offset>
    <c:length>4</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/15">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[you simply must. Her Smooth Operator buffer, ]$12[, is the best we've ever used ever and her]</c:detection>
    <c:prefix>you simply must. Her Smooth Operator buffer, </c:prefix>
    <c:exact>$12</c:exact>
    <c:suffix>, is the best we've ever used ever and her</c:suffix>
    <c:offset>1213</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/16">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[HAPPY BIRTHDAY and Marquee Moon lacquers, ]$16[-18.

We introduced you to DANNIJO jewels earlier]</c:detection>
    <c:prefix>HAPPY BIRTHDAY and Marquee Moon lacquers, </c:prefix>
    <c:exact>$16</c:exact>
    <c:suffix>-18.

We introduced you to DANNIJO jewels earlier</c:suffix>
    <c:offset>1368</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/17">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[and now we're obsessed with their Aris ring, ]$215[, which covers two fingers due to its three]</c:detection>
    <c:prefix>and now we're obsessed with their Aris ring, </c:prefix>
    <c:exact>$215</c:exact>
    <c:suffix>, which covers two fingers due to its three</c:suffix>
    <c:offset>1476</c:offset>
    <c:length>4</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/18">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[less buck? Try the blue cocktail ring above for ]$65[.If you can, we highly suggest adding bling to]</c:detection>
    <c:prefix>less buck? Try the blue cocktail ring above for </c:prefix>
    <c:exact>$65</c:exact>
    <c:suffix>.If you can, we highly suggest adding bling to</c:suffix>
    <c:offset>1608</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/19">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[Slip on Juicy Couture's Floral Cluster Ring, ]$88[, instead. Shown above, far right, this ring is a]</c:detection>
    <c:prefix>Slip on Juicy Couture's Floral Cluster Ring, </c:prefix>
    <c:exact>$88</c:exact>
    <c:suffix>, instead. Shown above, far right, this ring is a</c:suffix>
    <c:offset>1948</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/20">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[colors - Midnight Mambo and Teal We Meet Again, ]$9[, are hitting the spot for us today. Vibrant,]</c:detection>
    <c:prefix>colors - Midnight Mambo and Teal We Meet Again, </c:prefix>
    <c:exact>$9</c:exact>
    <c:suffix>, are hitting the spot for us today. Vibrant,</c:suffix>
    <c:offset>2152</c:offset>
    <c:length>2</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/21">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[mad manis in the comfort of your own home for ]$15[ a pack.

For a vivid color that dries faster]</c:detection>
    <c:prefix>mad manis in the comfort of your own home for </c:prefix>
    <c:exact>$15</c:exact>
    <c:suffix> a pack.

For a vivid color that dries faster</c:suffix>
    <c:offset>2464</c:offset>
    <c:length>3</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/22">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[ Sally Hansen Insta-Dri in Pronto Purple. At just ]$3[ a bottle, you now have no reason to show up to a]</c:detection>
    <c:prefix> Sally Hansen Insta-Dri in Pronto Purple. At just </c:prefix>
    <c:exact>$3</c:exact>
    <c:suffix> a bottle, you now have no reason to show up to a</c:suffix>
    <c:offset>2617</c:offset>
    <c:length>2</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Instance/23">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/InstanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <!--Currency: USD; -->
    <c:detection>[ go platinum? Pick up a bottle of Zoya in Trixie, ]$7[. Of course, you could always look be inspired by]</c:detection>
    <c:prefix> go platinum? Pick up a bottle of Zoya in Trixie, </c:prefix>
    <c:exact>$7</c:exact>
    <c:suffix>. Of course, you could always look be inspired by</c:suffix>
    <c:offset>2761</c:offset>
    <c:length>2</c:length>
  </rdf:Description>
  <rdf:Description rdf:about="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449/Relevance/10">
    <rdf:type rdf:resource="http://s.opencalais.com/1/type/sys/RelevanceInfo"/>
    <c:docId rdf:resource="http://d.opencalais.com/dochash-1/62cd6e22-f8fc-38e4-b937-476cf47b2449"/>
    <c:subject rdf:resource="http://d.opencalais.com/genericHasher-1/736a403d-157b-3e80-86a7-acc404607cb2"/>
    <c:relevance>0.831</c:relevance>
  </rdf:Description>
</rdf:RDF>
