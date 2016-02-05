package MangaWebsite::TuMangaOnline;

use strict;
use warnings;

use Helper;

sub new {
	my $class = shift;
	return bless({}, $class);
}

# Kinda tricky one, it has some asynchronous requests to get to the reader
sub getChapterList {	
	my ($self, $links, $http_response, $title, $url) = @_;
	my @manga_chapters;
	my $seen_chapter;

	print "Getting chapter list for: ". $title ."\n";

	foreach (split("\n", $http_response->decoded_content)) {
		if ($_ =~ /listaCapitulos\((\d+),([0-9.]+)/) {
			my $manga_id = $1;
			my $chapter_id = $2;

			next if ($seen_chapter->{$chapter_id});

			my $post_url = "http://www.tumangaonline.com/index.php?option=com_controlmanga&view=capitulos&format=raw";
			my $response = $main::ua->post(
				$post_url, 
				'Content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
				'X-Requested-With' => 'XMLHttpRequest',
				'Accept' => 'Accept',
				Content => {
					idManga => $manga_id, 
					idCapitulo => $chapter_id, 
				} 
			);

			my $pattern = "http://www.tumangaonline.com/visor/";
			if ($response && $response->decoded_content() =~ /data-enlace="($pattern)(.+)"\s+/) {
				unshift(@manga_chapters, { chapter => $chapter_id, url => $1.$2 });
				print "Chapter ". $chapter_id .": ". $1.$2 ."\n" if ($main::verbose);
			} else {
				logMsg("[". $title ."] Error: Unable to get chapter URL for chapter id ". $chapter_id);
			}
			$seen_chapter->{$chapter_id} = 1;
		}
	}

	return @manga_chapters;
}

sub ripChapter {
	my ($self, $manga_chapter, $manga_title) = @_;

	my $chapter_folder = $main::download_folder.'/'.$manga_title.'/'.$manga_chapter->{chapter};
	mkdir($chapter_folder) unless (-d $chapter_folder);

	my $chapter_info = $main::ua->get($manga_chapter->{url});

	# Get number of pages
	my $num_pages;
	if ($chapter_info && $chapter_info->decoded_content() =~ /\/(\d+)<\/option>\s*<\/select>/) {
		$num_pages = $1;
	} else {
		logMsg("[". $manga_title ."]Couldn't find the number of pages for chapter ". $manga_chapter->{chapter});
		return;
	}

	print "Downloading ". $num_pages ." pages from chapter ". $manga_chapter->{chapter} ."...\n";

	# Get the base URL for the images and all the images links
	my @pages;
	my $img_base_url = "http://img1.tumangaonline.com/subidas/";
	if ($chapter_info->decoded_content() =~ /<input id="1" hidden="true" value="(\d+);(\d+);(\d+);(.+);.+">/) {
		$img_base_url .= $1 ."/". $2 ."/". $3 ."/";
		@pages = split("%", $4);
	}

	# Download all pages
	for (my $page = 0; $page < $num_pages; $page++) {
		my $response = $main::ua->get($img_base_url.$pages[$page]);

		if ($response) {
			#Save the image
			open (my $fh, '>', $chapter_folder .'/'. ($page+1) .'.jpg');
			binmode($fh);
			print $fh $response->content();
			close($fh);
		} else {
			logMsg("[". $manga_title ." | Ch ". $manga_chapter->{chapter} ."]Error: Couldn't find image on ". $page ." page link")
		}
	}

	print "Download complete\n";
}

1;
