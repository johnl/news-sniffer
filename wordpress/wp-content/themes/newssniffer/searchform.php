<form method="get" id="searchbox" action="<?php bloginfo('home'); ?>/">
<div style="text-align: center"><input type="text" value="<?php echo wp_specialchars($s, 1); ?>" name="s" id="s" class="searchbox" />
<input type="submit" id="searchsubmit" value="Search" />
</div>
</form>
