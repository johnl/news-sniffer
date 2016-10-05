<?php get_header(); ?>

	<div id="content" class="narrow">

	<?php if (have_posts()) : ?>

		<?php while (have_posts()) : the_post(); ?>
      <article>
      <div class="post" id="post-<?php the_ID(); ?>">
        <header>
				<h2 class="posttitle"><a href="<?php the_permalink() ?>" rel="bookmark" title="Permanent Link to <?php the_title(); ?>"><?php the_title(); ?></a></h2>
				<small><?php the_time('F jS, Y') ?></small>
        </header>
				<div class="entry">
					<?php the_content('Read the rest of this entry &raquo;'); ?>
				</div>
        <footer>
  				<p class="postmetadata"><?php edit_post_link('Edit', '', ' | '); ?>  <?php comments_popup_link('No Comments &#187;', '1 Comment &#187;', '% Comments &#187;'); ?></p>
        </footer>
			</div>
      </article>
		<?php endwhile; ?>

    <nav>
		<div class="navigation">
			<div class="alignleft"><?php next_posts_link('&laquo; Previous Entries') ?></div>
			<div class="alignright"><?php previous_posts_link('Next Entries &raquo;') ?></div>
		</div>
    </nav>
	<?php else : ?>

		<h2 class="center">Not Found</h2>
		<p class="center">Sorry, but you are looking for something that isn't here.</p>
		<?php include (TEMPLATEPATH . "/searchform.php"); ?>

	<?php endif; ?>

	</div>

<?php get_footer(); ?>
