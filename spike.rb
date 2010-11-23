# encoding: utf-8
require "sinatra"
require "digest/sha1"

post "/upload" do
  if params[:file]
    checksum = Digest::SHA1.hexdigest params[:file][:tempfile].clone.to_s
    File.open checksum, "wb" do |f| f.write params[:file][:tempfile].read end
    p params[:file].class
  end
end

get "/upload" do
  "<html>
    <body>
      <form action=\"/upload\" method=\"post\" 
        enctype=\"multipart/form-data\" />
        <li><input type=\"file\" name=\"file\" /></li>
        <li><input type=\"submit\" value=\"submit\" /></li>
      </form>
    </body>
  </html>"
end
