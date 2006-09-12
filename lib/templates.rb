#
# RubyRSS
# Copyright (c) 2006 Sergey Tikhonov <st@dairon.net>
# Distributed under MIT License
#

$html_templates = { "default" => '
<h3><a href="#link">#title</a></h3>
<ul>

#items-start:5
<li><a href="#item-link">#item-title</a> (#item-date)<br/>
    #item-desc:100</li>
#items-end

</ul>
'
}

$rss_templates = { "rss2.0" => '
<?xml version="1.0" encoding="iso-8859-1"?>
<rss version="2.0">
<channel>
<title>#title</title>
<link>#link</link>
<description>#desc</description>
<pubDate>#date</pubDate>
<language>en-us</language>
<ttl>60</ttl>

#items-start
<item>
<title>#item-title</title>
<link>#item-link</link>
<description>#item-desc</description>
<pubDate>#item-date</pubDate>
<guid isPermaLink="true">#item-link</guid>
</item>
#items-end

</channel>
</rss>
'
}