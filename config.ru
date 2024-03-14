require 'uri'
require 'net/sftp'
require 'net/ssh/proxy/socks5'

PROXY_URI = URI.parse(ENV['IPB_SOCKS5'])
SFTP_URI = URI.parse(ENV['SFTP_URI'])

def list_sftp(&block)
  socks_proxy = Net::SSH::Proxy::SOCKS5.new(
    PROXY_URI.host,
    PROXY_URI.port,
    user: PROXY_URI.user,
    password: PROXY_URI.password
  )

  Net::SFTP.start(SFTP_URI.host, SFTP_URI.user, password: SFTP_URI.password, proxy: socks_proxy) do |sftp|
    sftp.dir.foreach('/', &block)
  end
end

app = proc do |_env|
  body = "Listing #{SFTP_URI} via proxy #{PROXY_URI}\n"
  list_sftp { |entry| body << "#{entry.longname}\n" }

  [200, { 'Content-Type' => 'text/plain', 'Content-Length' => body.length.to_s }, [body]]
end

run app
