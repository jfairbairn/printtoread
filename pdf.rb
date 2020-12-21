require 'json'
require 'prawn'
require 'nokogiri'
require 'net/http'
require 'xmlsimple'
require 'date'

urls = []
rss_url = 'https://feeds.pinboard.in/rss/secret:4e4c20a9d18a9c30969b/u:jfairbairn/toread/'

rss = Net::HTTP.get(URI.parse(rss_url))
rss_xml = XmlSimple.xml_in(rss)

rss_xml['item'].each_with_index do |item, i|
	urls << item['link'][0]
	break if i==2
end
docs = []

urls.each do |url|
	docs << JSON.parse(`mercury-parser #{url}`)
end
def fetch_image(url)
	if url =~ /\.(jpg|png|gif)/i
		filename = "tmp.#{$1}"
		begin
			File.open(filename, 'wb') {|f| f.write(Net::HTTP.get(URI.parse(url)))}
			move_down 2.4
			image(filename, width: bounds.width, fit: [bounds.width, bounds.height])
			move_down 2.4
		rescue
			# If Prawn doesn't like the image data, say
		ensure
			File.unlink(filename)
		end
	end
end

def font_path(collection)
	"/Library/Fonts/#{collection}.ttc"
end

Prawn::Document.generate('boudica.pdf') do
	font_path = "/Library/Fonts/Baskerville.ttc"
	font_families.update(
		"Baskerville" => {
			normal: { file: font_path("Baskerville"), font: "Baskerville Regular"},
			italic: { file: font_path("Baskerville"), font: "Baskerville Italic"},
			bold: { file: font_path("Baskerville"), font: "Baskerville Bold"},
			bold_italic: { file: font_path("Baskerville"), font: "Baskerville Bold Italic"},
			semibold: { file: font_path("Baskerville"), font: "Baskerville SemiBold"},
			semibold_italic: { file: font_path("Baskerville"), font: "Baskerville SemiBold Italic"}
		},
		"Cochin" => {
			normal: { file: font_path("Cochin"), font: "Cochin Regular"},
			italic: { file: font_path("Cochin"), font: "Cochin Italic"},
			bold: { file: font_path("Cochin"), font: "Cochin Bold"},
			bold_italic: { file: font_path("Cochin"), font: "Cochin Bold Italic"},
			semibold: { file: font_path("Cochin"), font: "Cochin Bold"},
			semibold_italic: { file: font_path("Cochin"), font: "Cochin Bold Italic"}
		},
		"Times New Roman" => {
			normal: { file: "/Library/Fonts/Times New Roman.ttf", font: "Times New Roman Regular"},
			italic: { file: "/Library/Fonts/Times New Roman Italic.ttf", font: "Times New Roman Italic"},
			bold: { file: "/Library/Fonts/Times New Roman Bold.ttf", font: "Times New Roman Bold"},
			bold_italic: { file: "/Library/Fonts/Times New Roman Bold Italic.ttf", font: "Times New Roman Bold Italic"},
			semibold: { file: "/Library/Fonts/Times New Roman Bold.ttf", font: "Times New Roman Bold"},
			semibold_italic: { file: "/Library/Fonts/Times New Roman Bold Italic.ttf", font: "Times New Roman Bold Italic"}
		}
	)
	font 'Times New Roman'
	font_size 10
	repeat(:all) do
		text "Prinstapaper—All the web that's fit to print", kerning: true, style: :bold
		move_up 11.5
		text DateTime.now.strftime("%A, %B %-d, %Y"), align: :right, kerning: true, style: :bold
		line_to bounds.width, 0
	end
	move_down 11.2
	column_box([0, cursor], columns: 2, width: bounds.width) do
		docs.each_with_index do |doc, i|
			move_down 11.2 unless i==0
			text doc['title'], size: 14, leading: 2, style: :bold_italic, kerning: true, align: :left
			text doc['author'], style: :italic, leading: 1.2
			text doc['excerpt'], style: :semibold, kerning: true, align: :justify, leading: 1.2
			# if doc['lead_image_url']
			# 	fetch_image(doc['lead_image_url'])
			# end
			html = Nokogiri::HTML(doc['content'])
			(html/'p, img, ul, ol').each do |x|
				case x.name
				when 'p'
					text x.inner_text, align: :justify, kerning: true, indent_paragraphs: 10, leading: 1.2
				when 'img'
					fetch_image x['src'] unless x['src'] == doc['lead_image_url']
				end
			end
		end
	end
	number_pages '<page>', at: [0, bounds.left], width: bounds.width, align: :center
end

