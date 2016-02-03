package MangaWebsite::Mangahere;

use strict;
use warnings;
use parent 'MangaWebsite';
use Helper qw(logMsg);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new($class);
	return $self;
}

sub rip {
	my ($self, $manga) = @_;
	mkdir($main::download_folder.'/'.$manga->{title}) unless (-d $main::download_folder.'/'.$manga->{title});
	my $url = $main::sites{mangahere} . $manga->{title};
	my $response = $main::ua->get($url);
	
	if ($response) {
		my @links = $main::ua->links();
		my @manga_chapters = getChapterList(\@links, $manga->{title}, $url);
		my $constraints = $self->SUPER::checkConstraints($manga->{ch_start}, $manga->{ch_end}, scalar(@manga_chapters));

		# We have the links for the chapter and information from where to start and where to end
		if (@manga_chapters) {
			print "Found ". scalar(@manga_chapters) ." chapters\n";

			# Rip each chapter
			for (my $index = $constraints->{start}; $index < $constraints->{end}; $index++) {
				ripChapter($manga_chapters[$index], $manga->{title});
			}
		} else {
			logMsg("[". $manga->{title} ."] Error: No chapters found");
		}
	} else {
		logMsg("[". $manga->{title} ."] Error: Unable to GET ". $url);
	}
}

sub getChapterList {
	my ($links, $title, $url) = @_;
	my @manga_chapters;
	my $seen_chapter;

	print "Getting chapter list for: ". $title ."\n";

	foreach (@$links) {
		if ($_->url() =~ /$url.*\/c([0-9.]+)/) {
			next if ($seen_chapter->{$1});
			print "Chapter ". $1 .": ". $_->url() ."\n" if ($main::verbose);
			unshift(@manga_chapters, { chapter => $1, url => $_->url() });
			$seen_chapter->{$1} = 1;			
		}
	}

	return @manga_chapters;
}

sub ripChapter {
	my ($manga_chapter, $manga_title) = @_;

	my $chapter_folder = $main::download_folder.'/'.$manga_title.'/'.$manga_chapter->{chapter};
	mkdir($chapter_folder) unless (-d $chapter_folder);

	my $chapter_info = $main::ua->get($manga_chapter->{url});

	# Get number of pages
	my $num_pages;
	if ($chapter_info && $chapter_info->decoded_content() =~ /(\d+)<\/option>\s*<\/select>/) {
		$num_pages = $1;
	} else {
		logMsg("[". $manga_title ."]Couldn't find the number of pages for chapter ". $manga_chapter->{chapter});
		return;
	}

	print "Downloading ". $num_pages ." pages from chapter ". $manga_chapter->{chapter} ."...\n";

	for (my $page = 1; $page <= $num_pages; $page++) {
		my $response = $main::ua->get($manga_chapter->{url} . $page . ".html");
		if ($response) {
			# Find the image by its alt tag
			my $image_obj = $main::ua->find_image(alt_regex => qr/page \d+$/i);
			if ($image_obj) {
				my $image = $main::ua->get($image_obj->url());
				print "Downloading page ". $page ."\n" if ($main::verbose);

				#Save the image
				open (my $fh, '>', $chapter_folder .'/'. $page .'.jpg');
				binmode($fh);
				print $fh $image->content();
				close($fh);

			} else {
				logMsg("[". $manga_title ." | Ch ". $manga_chapter->{chapter} ."]Error: Couldn't find image on ". $page ." page link\n");
			}
		} else {
			logMsg("[". $manga_title ." | Ch ". $manga_chapter->{chapter} ."]Error: Couldn't download page ". $page);
		}
	}

	print "Download complete";
}

1;