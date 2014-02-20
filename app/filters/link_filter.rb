# encoding: utf-8

class LinkFilter < Filter

  #  *.youtube.com
  HTTPS_WHITELIST = %w{
    youtube.com
    vimeo.com
    soundcloud.com
    i.imgur.com
    *.cloudfront.net
    *.s3.amazonaws.com
  }

  def process(post)
    @post = post
    relativize_local_links!
    rewrite_for_https_support!
    parser.to_html
  end

  private

  def local_domains
    Sugar.config.domain_names.try(:strip).try(:split, /\s*,\s*/)
  end

  def parser
    @parser ||= Nokogiri::HTML::DocumentFragment.parse(@post)
  end

  def matches_https_whitelist?(url)
    host = URI.parse(url).host
    HTTPS_WHITELIST.find { |domain| File.fnmatch(domain, host) }
  end

  def url_exists?(url)
    uri = URI.parse(url.gsub(/^(https?:)\/\//, "https://"))

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 2
    http.read_timeout = 5

    begin
      http.start do |http|
        http.head(uri.request_uri).code =~ /^(2|3)\d\d$/
      end
    rescue SocketError, Net::OpenTimeout
      false
    end
  end

  def relativize_local_links!
    parser.search("a").each do |link|
      if href = link.try(:attributes).try(:[], 'href').try(:value)
        host = URI.parse(href).host
        if local_domains.find { |d| host == d }
          link.set_attribute 'href', href.gsub(Regexp.new("(https?:)?\/\/" + Regexp.escape(host)), "")
        end
      end
    end
  end

  def rewrite_for_https_support!
    parser.css("iframe,img").each do |iframe|
      if src = iframe.try(:attributes).try(:[], 'src').try(:value)
        if matches_https_whitelist?(src) || (src =~ /\Ahttp:\/\// && url_exists?(src))
          iframe.set_attribute 'src', src.gsub(/\Ahttps?:\/\//, "//")
        end
      end
    end
  end
end