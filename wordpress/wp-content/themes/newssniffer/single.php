<?php get_header(); ?>

	<div id="content" class="narrow">

  <?php if (have_posts()) : while (have_posts()) : the_post(); ?>
    <article>
    <div class="post" id="post-<?php the_ID(); ?>">
      <header>
			<h2 class="posttitle"><a href="<?php echo get_permalink() ?>" rel="bookmark" title="Permanent Link: <?php the_title(); ?>"><?php the_title(); ?></a></h2>
      <small><?php the_time('l, F jS, Y') ?> at <?php the_time() ?></small>
      </header>
			<div class="entry">
				<?php the_content('<p class="serif">Read the rest of this entry &raquo;</p>'); ?>

				<?php link_pages('<p><strong>Pages:</strong> ', '</p>', 'number'); ?>

			</div>
		</div>
    </article>
	<?php comments_template(); ?>

	<?php endwhile; else: ?>

		<p>Sorry, no posts matched your criteria.</p>

<?php endif; ?>

	</div>

<?php get_footer(); ?>
