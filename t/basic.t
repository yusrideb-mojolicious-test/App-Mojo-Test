use Mojo::Base -strict;

use Test::More;
use App::Test::Mojo;

my $t = App::Test::Mojo->new('App::MojoTest');
$t->get_ok('/')->status_is(200)

  # Header and Content Type Testing
  ->header_is(Server => 'Mojolicious (Perl)', 'Server Header with description')
  ->content_type_is('text/html;charset=UTF-8', 'Content Type with description')

  # HTML Tag with attributes lang
  ->attr_like('html', 'lang' => qr/en/)

  # General tag in HEAD Tag
  ->element_exists('html head meta',  'head style exists')
  ->element_exists('html head link',  'head link exists')
  ->element_exists('html head style', 'head style exists')
  ->element_exists('html head title', 'head style exists')

  # For Meta Tag
  ->element_exists('html head meta[charset]', 'meta tag charset exists')
  ->attr_is('head meta', 'charset', 'utf-8', 'meta charset utf8 exists')
  ->attr_like('head meta[name]', 'name', qr/viewport/, 'meta viewport exists')
  ->attr_like('head meta[name=viewport]',
  'content' => qr/width|initial-scale|shrink-to-fit/)
  ->attr_is('head meta[name=description]',
  'content' => 'Example Bootstrap Blog Template')
  ->attr_isnt('head meta[name=description]',
  'content' => 'Example Boostrap Blog Template')

  # Head Link attribute "rel"
  ->attr_like('head link', 'rel', qr/canonical|manifest|stylesheet|icon|/)
  ->element_count_is('head link[rel]', 10)

  # For favicon
  ->attr_like('head link[rel=icon]', href => qr/favicon|icon.png|apple|.ico/)
  ->attr_unlike('head link[rel=icon]', href => qr/favcon|iconpng|aple|.icod/)
  ->attr_is('head link[rel=mask-icon]',    'color'   => '#563d7c')
  ->attr_isnt('head link[rel=mask-icon]',    'color'   => '#563c7c')
  ->attr_is('head meta[name=theme-color]', 'content' => '#563d7c')
  ->attr_isnt('head meta[name=theme-color]', 'content' => '#568d7c')
  ->element_count_is('head link[rel=apple-touch-icon]',      1)
  ->element_count_is('head link[rel=icon]',                  3)
  ->element_count_is('head link[rel=mask-icon]',             1)
  ->element_count_is('head link[rel=manifest]',              1)
  ->element_count_is('head meta[name=msapplication-config]', 1)
  ->element_count_is('head meta[name=theme-color]',          1)

  # For Stylesheet
  ->attr_like('head link[rel="stylesheet"]',
  'href' => qr/bootstrap|blog|playfair|fonts.googleapis.com/)
  ->element_count_is('head link[rel="stylesheet"]', 3)

  # For Body Header
  ->element_exists('body header')
  ->element_exists('body nav')
  ->attr_is('body nav a', 'data-tag' => 'navbar-test')
  ->attr_like('body nav a', 'data-tag' => qr/nav/)
  ->attr_like('body nav a', 'data-tag' => qr/bar/)
  ->attr_like('body nav a', 'data-tag' => qr/test/)
  ->element_count_is('body nav a[data-tag]', 12)
  
  # For Body Main Content
  ->element_exists('body main')
  ->attr_is('body main[role=main]', class => 'container')
  ->attr_is('body main[role=main] div', class => 'row')
  ->attr_isnt('body main[role=main] div', class => 'col')
  ->attr_like('body main[role=main] div.row div', class => qr/col-/)
  ->attr_unlike('body main[role=main] div.row div', class => qr/row/)
  ->attr_like('body main[role=main] div.row div h3', class => qr/font-italic|border-bottom/)
  ->attr_like('body main[role=main] div.row div div', class => qr/blog-post/)
  ->attr_unlike('body main[role=main] div.row div div', class => qr/blogpost/)
  ->attr_like('body main[role=main] div.row div nav', class => qr/blog-pagi/)
  ->attr_unlike('body main[role=main] div.row div nav', class => qr/blogpagi/)
  ->element_count_is('body main[role=main] div.row div div.blog-post' => 3)
  ->element_count_is('body main[role=main] div.row div nav.blog-pagination' => 1)
  
  # For Body Sidebar
  ->element_exists('body main[role=main] div.row aside')
  ->attr_like('body main[role=main] div.row aside', class => qr/col-|blog|side|sidebar/)
  ->attr_unlike('body main[role=main] div.row aside', class => qr/co-|blg|sde|sidbar/)
  ->attr_like('body main[role=main] div.row aside h4', class => qr/font-italic/)
  ->attr_unlike('body main[role=main] div.row aside h4', class => qr/font-talic/)
  ->element_count_is('body main[role=main] div.row aside h4', 3)
  
  # For Footer
  ->element_exists('body footer')
  ->attr_like('body footer', class => qr/blog|footer/)
  ->attr_unlike('body footer', class => qr/blOg|foOter/)
  ->attr_like('body footer a', href => qr/bootstrap|twitter/)
  ->element_count_is('body footer p', 2)
  ->element_count_is('body footer a', 3)
  ;

done_testing();
