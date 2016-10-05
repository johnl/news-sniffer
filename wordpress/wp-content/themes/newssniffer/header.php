<!DOCTYPE html> 
<html> 
  <head> 
    <meta http-equiv="Content-Type" content="<?php bloginfo('html_type'); ?>; charset=<?php bloginfo('charset'); ?>" />
    <title><?php bloginfo('name'); ?> <?php if ( is_single() ) { ?> &raquo; Archive <?php } ?> <?php wp_title(); ?></title>
    <link rel="stylesheet" href="/stylesheets/newsniffer.css?100615" type="text/css" media="screen" />
    <link rel="stylesheet" href="<?php bloginfo('stylesheet_url'); ?>" type="text/css" media="screen" />
    <link rel="alternate" type="application/rss+xml" title="<?php bloginfo('name'); ?> RSS Feed" href="<?php bloginfo('rss2_url'); ?>" />
    <link rel="pingback" href="<?php bloginfo('pingback_url'); ?>" />
<?php wp_head(); ?>
  </head>
  <body>
    <header>
    <div id="header">
      <img src="/stylesheets/layout/newsniffer-text.png" alt="News Sniffer" id="logo"/>
      <nav>
  	  <div id="nav"> 
        <ul>
      	  <li><a href="/versions">News Article Revisions</a></li>
      	  <li><a href="/blog/" class="selected">Blog</a></li>
      	  <li><a href="/blog/about">About</a></li>
        </ul>
      </div> 
      </nav>
    </div>
    </header>
    <div id="crossbar">
    </div>
      <div id="sidebar">
        <?php get_sidebar(); ?>      
      </div>
