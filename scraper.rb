# this script borrows heavily from https://github.com/planningalerts-scrapers/moreland
# unlike the Planning Alerts scraper, which scrapes for new planning applications, this scraper gleans
# planning applications for which a decision has been made (by the council)

require 'mechanize'
require 'scraperwiki'

agent = Mechanize.new

#agent.log = Logger.new "mechanize.log"


url="https://eservices.moreland.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/ExternalRequestBroker.aspx?Module=EGELAP&Class=SUB&Type=SUBDEC"

def scrape_page(page, detailpageurlprefix)
  table = page.at("table.ContentPanel")
  table.search("tr")[1..-1].each do |tr|
    day, month, year = tr.search("td")[1].inner_text.split("/").map{|s| s.to_i}

   # puts 
    record = {
      # the href is just the suffix, i.e EnquiryDetailView.aspx?Id=977780	
      "info_url" => detailpageurlprefix + tr.at("td a").attr("href"),
      "council_reference" => tr.at("td a").inner_text,
      "date_received" => Date.new(year, month, day).to_s,
      "description" => tr.search("td")[2].inner_text,
      "address" => tr.search("td")[3].inner_text,
      "decision" => tr.search("td")[4].inner_text,
      "date_scraped" => Date.today.to_s
    }

    ScraperWiki.save_sqlite(['council_reference'], record)
     
  #  return record
    
  end
end

# to get to the page we're really interested in - the page with the table of planning applications - we must first
# visit the prior page.  This ensures the relevant session cookies are setup

page = agent.get(url)

# move through first page 
form = page.forms.first

secondPage = form.submit(form.button_with(value: "Search"))
#puts secondPage.uri
#pp secondPage

# Now do the paging magic
number_pages = secondPage.at("#ctl00_MainBodyContent_mPagingControl_pageNumberLabel").inner_text.split(" ")[3].to_i
#puts number_pages

#applications = []

## iterate and scrape every page
(1..number_pages).each do |no|
##(1..3).each do |no|
  
  decisionPage = agent.get("https://eservices.moreland.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquirySummaryView.aspx?PageNumber=#{no}")
  #puts "Scraping page #{no} of results..."
  scrape_page(decisionPage, "https://eservices.moreland.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/")
  #puts hashRecord.to_json

  
#  applications << application

end

#puts applications

# Setup a specific instance of an Azure::Storage::Client
#  client = Azure::Storage::Client.create(:storage_account_name => 'your account name', :storage_access_key => 'your access key')


# puts number_pages

#agent.log = Logger.new "mechanize.log"
