package MangaWebsite::LerManga;

use strict;
use warnings;
use MIME::Base64 qw(decode_base64);
use JSON qw(decode_json);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

use Helper;

sub new {
	my $class = shift;
	return bless({}, $class);
}

sub getChapterList {
	my ($self, $links, $http_response, $title, $url) = @_;
	my @manga_chapters;
	my $seen_chapter;

	print "Getting chapter list for: ". $title ."\n";

	foreach (@$links) {
		if ($_->url() =~ /$url.*\/capitulo-([0-9.]+)/) {
			next if ($seen_chapter->{$1});
			print "Chapter ". $1 .": ". $_->url() ."\n" if ($main::verbose);
			unshift(@manga_chapters, { chapter => $1, url => $_->url() });
			$seen_chapter->{$1} = 1;			
		}
	}

	return @manga_chapters;
}

sub ripChapter {
	my ($self, $manga_chapter, $manga_title) = @_;

	my $chapter_folder = $main::download_folder.'/'.$manga_title.'/'.$manga_chapter->{chapter};
	mkdir($chapter_folder) unless (-d $chapter_folder);

	my $chapter_info = $main::ua->get($manga_chapter->{url});

	# Get the base64 with the JSON structure of page/link
	my $json_info;
	if ($chapter_info->decoded_content() =~ /<div id="js_co_chap_imgs".+">(.+)<\/div><\/article>/) {
		my $str = decode_base64(substr($1, 0, -2));
		$str =~ s/\\\//\//g;
		$json_info = decode_json($str);
	} else {
		logMsg("[". $manga_title ."] Error: Unable to get information about the pages of chapter ". $manga_chapter);
	}

	print "Downloading ". scalar(@$json_info) ." pages from chapter ". $manga_chapter->{chapter} ."...\n";

	foreach my $page (@$json_info) {
		print "Downloading page ". $page->{page} ."\n" if ($main::verbose);
		my $image = $main::ua->get(URI->new($page->{image}));
		if ($image) {
			my $img_format = substr($page->{image},-3);
			my $image_unzipped;
			gunzip \$image->content()=> \$image_unzipped;
			open (my $fh, '>', $chapter_folder .'/'. $page->{page} .'.'. $img_format) or die ($!);
			binmode($fh);
			print $fh $image_unzipped;
			close($fh);
		} else {
			logMsg("[". $manga_title ." | Ch ". $manga_chapter->{chapter} ."]Error: Couldn't find image on ". $page->{page} ." page link");
		} 
	}

	print "Download complete\n";
}

1;