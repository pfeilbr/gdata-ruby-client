require 'rubygems'
require 'httpclient'
require 'hpricot'
require 'ostruct'
require 'pp'

class GoogleDocsManager
  
  CLIENTLOGIN_URL = 'https://www.google.com/accounts/ClientLogin'
  DOCS_PRIVATE_URL = 'http://docs.google.com/feeds/documents/private/full'
  SOURCE = 'brianpfeil.com-gdata_manager-1.0'
  
  attr :client
  
  def initialize(email, password)
    @email = email
    @password = password
    @client = HTTPClient.new
    @auth = nil
    
    login if !authorized?
  end
  
  def authorized?
    @auth != nil
  end
  
  def login
    response = @client.post(CLIENTLOGIN_URL, {:accountType => 'HOSTED_OR_GOOGLE', :Email => @email, :Passwd => @password, :service => 'writely', :source => SOURCE})
    @auth = response.content[/Auth=(.*)/,1]
  end
  
  def default_headers
    {'Authorization' => "GoogleLogin auth=#{@auth}", 'GData-Version' => '2.0'}
  end
  
  def list_xml
    @client.get_content(DOCS_PRIVATE_URL, nil, default_headers)
  end
  
  # returns array of documents containing id, title, & export_url
  def docs
    doc_list = []
    xml = list_xml
    doc = Hpricot(xml)
    (doc/"entry").each do |entry|
      doc = OpenStruct.new
      doc.id = (entry/"id").inner_html
      doc.title = (entry/"title").inner_html
      doc.content_type = (entry/"content").first.attributes['type']
      doc.export_url = (entry/"content").first.attributes['src']
      doc_list << doc
    end
    doc_list
  end

  def download_doc(export_url)
    @client.get_content(export_url, nil, default_headers.merge({'Content-Type' => 'text/html'}) )
  end

  def upload_doc(name, contents, content_type)
    @client.post(DOCS_PRIVATE_URL, contents, default_headers.merge({'Content-Type' => content_type, 'Slug' => name}) )
  end
    
  def upload_html_doc(name, html)
    upload_doc(name, html, 'text/html')
  end
  
end

EMAIL = 'brian.pfeil@gmail.com'
PASSWORD = '<password here>'

def run_upload
  # uploads html as a google document
  mngr = GoogleDocsManager.new(EMAIL, PASSWORD)
  response = mngr.upload_html_doc('hello world 2', '<html><body>hello world</body></html>')
  if response.status == 201
    puts "upload succeeded"
  else
    puts "upload failed. http status code = #{response.status}\nresponse.content=\n#{response.content}"
  end
end

def run_list
  mngr = GoogleDocsManager.new(EMAIL, PASSWORD)
  mngr.docs.each do |doc|
    puts mngr.download_doc(doc.export_url)
    exit
  end
end

run_upload

def upload_personal_knowledge_base_items
  mngr = GoogleDocsManager.new('brian.pfeil@gmail.com', 'method00')
  
  # temporary snippet to load personal knowledge base items as google docs
  open("/Users/brianpfeil/Temp/items.txt").read.split("||::||").each do |item|
    components = item.split("|||")
    name = components[0]
    html = components[1]
    puts "upoading #{name}"
    response = mngr.upload_html_doc(name, html)
    if response.status != 201
      puts response.status
      puts response
      exit
    end  
  end
end