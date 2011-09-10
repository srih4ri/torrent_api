module PirateBay
  class Browse
    attr_accessor  :category_id, :page, :caching, :results

    def initialize(category='movies')
      self.category_id = PirateBay::Categories::IDS[category.upcase.strip.gsub(/S$/, "").to_sym] unless category == 0
      self.page = 0

      @results = PirateBay::ResultSet.new(self)
    end

    def get_search_results
      if caching && File.exists?(cached_filename)
        content = File.read(cached_filename)
      else
        content = fetch_search_results

        FileUtils.mkdir_p("tmp/browse")
        File.open(cached_filename, "w") do |f|
          f.write(content)
        end
      end
      content
    end

    def execute
      self.page += 1

      if (@results.size < @results.total_results)
        doc = Nokogiri::HTML(get_search_results)
      end

      next_page(doc)

    end

    def cached_filename
      File.join("tmp", "browse", "#{category_id}_#{page}.html")
    end

    def browse_url
      "http://thepiratebay.org/browse/#{category_id}/#{page}/7" # highest seeded first
    end
    def fetch_search_results
      uri = URI.parse(browse_url)

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      response.body
    end

    private

    def next_page(doc)
      if @results.total_results.nil?
        matching_results = doc.css("h2").first.content.match(/Displaying hits from (.*) to (.*) \(approx (.*) found\)/i)

        if (matching_results.nil?)
          @results.total_results = 0
        else
          @results.total_results = matching_results[3].to_i
        end
      end
      links = doc.css("#searchResult tr")
      links[0..links.length-2].each_with_index do |row, index|
        next if index == 0
        result = PirateBay::Result.new(row)
        @results << result
      end
      @results
    end

  end


end