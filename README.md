# MangaRipper
A Perl script to download mangas from popular manga websites

### Current websites supported
* [MangaHere](http://www.mangahere.co/) (english)
* [TuMangaOnline](http://www.tumangaonline.com/) (spanish)

### Installation

You need a Perl interpreter installed in your computer to run this script. If you're using a UNIX-like operating system like Linux or Mac, you probably already have it by default. If you're on Windows, I recommend [Strawberry Perl](http://strawberryperl.com/).

MangaRipper requires the WWW::Mechanize module to work. If you don't have it, you can install it through CPAN. Once you already installed a Perl interpreter just open your Terminal and type:

`sudo cpan install WWW::Mechanize`

Or if you're in Windows, just open the Command Prompt and type:

`cpan install WWW::Mechanize`

That's it. Now you only have to run `MangaRipper.pl` once you're set things up.

### Settings

The only file you have to worry about is `manga_list.txt`. If you downloaded MangaRipper as clone from Github instead of one of the releases, the file name is `manga_list.txt.sample`. Just rename it to `manga_list.txt` and you're done.

In this file you'll paste the URLs to the manga series you wish to download. You may as well inform the chapters you wish to download. Basically an entry goes like this:

(`MANGA_URL`, `START_CHAPTER`, `END_CHAPTER`)

`MANGA_URL` is the link to the page where all the links to the chapters of the manga are listed. For example, in MangaHere it goes like `http://www.mangahere.co/manga/<manga name>/` while TuMangaOnline is `http://www.tumangaonline.com/listado-mangas/manga/<manga id>/<manga name>`.

`MANGA_URR` and `END_CHAPTER` are optional, you can leave it blank (but you must not forget the comma). MangaRipper will try to download the chapters from the series starting from `START_CHAPTER` until `END_CHAPTER`. These values default to the first and last available chapters respectively in case you don't fill anything.

Once you run `MangaRipper.pl`, it will check this file and download all the entries you informed and save them to the subfolder folder `downloads` (don't worry, it will create one by itself if it doesn't exist). Inside the downloads folder each series will be divided in folders (each with the series names) and inside those folders are the folders for each chapter of the series.

If any error happens, say, it wasn't able to download a page, it will get logged in a file called `log.txt`. So before reading, you should check this file first (it automatically appears in the root folder if anything goes wrong).
