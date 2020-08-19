require 'nokogiri'
require 'csv'
require 'curb'

class Scraper
    attr_accessor :url, :filename

    def initialize (url, filename)
        @url = url
        @filename = filename
    end
#Download page function
    def httpFunc (url)
        http = Curl::Easy.new(url) 
        http.ssl_verify_peer = false
        http.perform
        return http
    end
#Parse Function
    def parseFunc (http)
        parse_page = Nokogiri::HTML(http.body_str)
        return parse_page
    end
#Search items function
    def searchLink (parse_page)
        pages = []
        parse_page.xpath('//*[@class = "product_img_link pro_img_hover_scale product-list-category-img"]' ).each do |a|
            tempUrl = a.get_attribute('href')
            pages.push(tempUrl)
        end
        return pages
    end
#Search product info function
    def searchInfo (parse_page)
        information = []
        product_Price = []
        product_Weight = []
        product_Name = parse_page.xpath('//*[@class = "product_main_name"]').text
        product_Img = parse_page.xpath('//*[@class = "replace-2x"]/@src')
        parse_page.xpath('//*[@class = "radio_label"]').each do |e|
            product_Weight.push(e.text())
        end
        parse_page.xpath('//*[@class = "price_comb"]').each do |e|
            product_Price.push(e.text())
        end
        i = 0
        count = product_Price.count
        begin 
            information.push(product_Name + product_Weight[i], product_Price[i], product_Img)
            count = count - 1
            i = i + 1
        end until count == 0
        return information 
    end
#Pagination
    def cheackItemsCount (pages)
        page_number = 1
        per_page = pages.count
        pag_pages = []
        while per_page >= 25
            page_number = page_number + 1
            pag_url = @url + "?p=#{page_number}"
            temphttp = httpFunc(pag_url)
            temphtml = parseFunc(temphttp)
            pag_pages = pag_pages + searchLink(temphtml)
            per_page = pag_pages.count
        end
        pag_pages.each do |p|
            pages.push(p)
        end
        return pages
    end
#Write file function
    def writeFile (fname, pages)
        x = pages.length
        CSV.open(fname,"wb") do |csv|
            csv << ["Name", "Price", "Image"]
            pages.each do |p|
                puts "Getting product info..."
                puts  x.to_s + " items left \n\n" 
                tempHtml = parseFunc(httpFunc(p))
                searchInfo(tempHtml).each do |e|
                    csv << [e]
                end
                x = x - 1
            end
        end
    end
end
#Main
puts "Enter url:"
url = gets.chomp
puts "Enter file name:"
fname = gets.chomp + ".csv"
parser = Scraper.new(url, fname)
pages = []
http = parser.httpFunc(parser.url)
html = parser.parseFunc(http)
pages = parser.searchLink(html)
pagination = parser.cheackItemsCount(pages)
pages = pages + pagination
parser.writeFile(parser.filename, pages)

