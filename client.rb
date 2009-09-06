require 'rubygems'
require 'httpclient'

class GoogleDocsManager
  
  CLIENTLOGIN_URL = 'https://www.google.com/accounts/ClientLogin'
  DOCS_PRIVATE_URL = 'http://docs.google.com/feeds/documents/private/full'
  SOURCE = 'brianpfeil.com-gdata_manager-1.0'
  
  def initialize(email, password)
    @email = email
    @password = password
    @client = HTTPClient.new
    @auth = nil
  end
  
  def authorized?
    @auth != nil
  end
  
  def login
    response = @client.post(CLIENTLOGIN_URL, {:accountType => 'HOSTED_OR_GOOGLE', :Email => @email, :Passwd => @password, :service => 'writely', :source => SOURCE})
    @auth = response.content.split("\n")[2]
  end
  
  def upload_html_doc(name, html)
    login if !authorized?
    @client.post(DOCS_PRIVATE_URL, html, {'Authorization' => "GoogleLogin #{@auth}", 'Content-Type' => 'text/html', 'Slug' => name})
  end
  
end

# uploads html as a google document
mngr = GoogleDocsManager.new('brian.pfeil@gmail.com', '<password here>')
mngr.upload_html_doc('hello world', '<html><body>hello world</body></html>')
puts response.status # 201 is success

exit

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
