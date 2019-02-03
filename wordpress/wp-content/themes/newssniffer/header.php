<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="<?php bloginfo('html_type'); ?>; charset=<?php bloginfo('charset'); ?>" />
    <title><?php bloginfo('name'); ?> <?php if ( is_single() ) { ?> &raquo; Archive <?php } ?> <?php wp_title(); ?></title>
	<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <link rel="stylesheet" href="/assets/application.css" type="text/css" media="screen" />
	<!--[if lt IE 9]>
        <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    <link href="/versions.rss" rel="alternate" title="RSS feed of all news article versions" type="application/rss+xml" />

    <link rel="stylesheet" href="<?php bloginfo('stylesheet_url'); ?>" type="text/css" media="screen" />
    <link rel="alternate" type="application/rss+xml" title="<?php bloginfo('name'); ?> RSS Feed" href="<?php bloginfo('rss2_url'); ?>" />
    <link rel="pingback" href="<?php bloginfo('pingback_url'); ?>" />
<?php wp_head(); ?>
</head>
<body>
    <header>
        <div id="header" class="header">
  			<div class="logo-head">
				<a href="/"><img src="/images/newsniffer-text.png" alt="News Sniffer" class="logo" id="logo" /></a>
			</div>
			<div class="toggle-nav">
	            <span class="bar"></span>
	            <span class="bar"></span>
	            <span class="bar"></span>
             </div>
			<nav class="navigation">
				<ul id="nav" class="menu">
					<li><a href="https://www.newssniffer.co.uk/versions" title="News article Revisions">News Article Revisions</a></li>
					<li><a class="selected" href="/blog/">Blog</a></li>
					<li><a href="/blog/about">About</a></li>
				</ul>
			</nav>
        </div>
    </header>
    <div id="content" class="content">
      <div class="wrap">
