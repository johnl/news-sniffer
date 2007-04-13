CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) default NULL,
  `text` text,
  `email` varchar(64) default NULL,
  `link_id` int(11) default NULL,
  `linktype` varchar(32) default NULL,
  PRIMARY KEY  (`id`),
  KEY `comments_link_id_index` (`link_id`),
  KEY `comments_linktype_index` (`linktype`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `hys_comments` (
  `id` int(11) NOT NULL auto_increment,
  `hys_thread_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `bbcid` mediumint(9) default NULL,
  `updated_at` datetime default NULL,
  `text` text,
  `author` varchar(128) default NULL,
  `censored` tinyint(4) default '1',
  `modified_at` datetime default NULL,
  `votes` int(11) default '0',
  PRIMARY KEY  (`id`),
  KEY `hys_thread_id_key` (`hys_thread_id`),
  KEY `bbcid_key` (`bbcid`),
  KEY `hys_comments_votes_index` (`votes`),
  KEY `hys_comments_updated_at_index` (`updated_at`),
  KEY `censored` (`censored`),
  FULLTEXT KEY `text` (`text`)
) ENGINE=MyISAM AUTO_INCREMENT=328144 DEFAULT CHARSET=latin1;

CREATE TABLE `hys_threads` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `bbcid` mediumint(9) default NULL,
  `title` varchar(255) NOT NULL,
  `rsssize` int(11) default NULL,
  `last_rss_pubdate` datetime default NULL,
  `description` text,
  PRIMARY KEY  (`id`),
  KEY `bbcid_key` (`bbcid`)
) ENGINE=MyISAM AUTO_INCREMENT=725 DEFAULT CHARSET=latin1;

CREATE TABLE `news_article_versions` (
  `id` int(11) NOT NULL auto_increment,
  `news_article_id` int(11) default NULL,
  `title` varchar(200) default NULL,
  `url` varchar(250) default NULL,
  `created_at` datetime default NULL,
  `version` int(11) default NULL,
  `text` text,
  `text_hash` varchar(32) default NULL,
  `comments_count` int(11) default '0',
  `votes` int(11) default '0',
  PRIMARY KEY  (`id`),
  KEY `news_article_versions_news_article_id_index` (`news_article_id`),
  KEY `news_article_versions_text_hash_index` (`text_hash`),
  KEY `news_article_versions_comments_count_index` (`comments_count`),
  KEY `news_article_versions_votes_index` (`votes`),
  FULLTEXT KEY `title_and_text` (`title`,`text`)
) ENGINE=MyISAM AUTO_INCREMENT=59512 DEFAULT CHARSET=latin1;

CREATE TABLE `news_articles` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `source` varchar(32) default NULL,
  `guid` varchar(200) default NULL,
  `url` varchar(250) default NULL,
  `title` varchar(200) default NULL,
  `published_at` datetime default NULL,
  `latest_text_hash` varchar(32) default NULL,
  `versions_count` int(11) default '0',
  PRIMARY KEY  (`id`),
  KEY `news_articles_guid_index` (`guid`),
  KEY `news_articles_source_index` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `variables` (
  `id` int(11) NOT NULL auto_increment,
  `key` varchar(30) default NULL,
  `value` varchar(250) default NULL,
  PRIMARY KEY  (`id`),
  KEY `key_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `votes` (
  `id` int(11) NOT NULL auto_increment,
  `sessionid` varchar(32) default NULL,
  `created_at` datetime default NULL,
  `class` varchar(32) default NULL,
  `relation_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `votes_sessionid_index` (`sessionid`),
  KEY `votes_class_index` (`class`),
  KEY `votes_relation_id_index` (`relation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_info (version) VALUES (11)