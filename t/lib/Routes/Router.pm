
package Routes::Router;

use strict;
use warnings 'all';
use base qw( ASP4::TransHandler ASP4::RequestFilter );
use Router::Generic;
use ASP4::ConfigLoader;
use vars __PACKAGE__->VARS;


sub handler : method
{
  my ($class, $r) = @_;
  
  $ENV{DOCUMENT_ROOT} = $r->document_root;
  $class->SUPER::handler( $r );
  
  # Setup our router according to the config:
  my $router = Router::Generic->new();
  my $Config = ASP4::ConfigLoader->load();
  my $routes = eval { $Config->web->routes } or return -1;
  eval { @$routes } or return -1;
  map { $router->add_route( %$_ ) } @$routes;
  
  my $new_uri = $router->match( $r->uri . ( $r->args ? '?' . $r->args : '' ) )
    or return -1;
  
  # Require a trailing '/' on the end of the URI:
  unless( $r->uri =~ m{/$} )
  {
    my $loc = $r->uri . '/';
    $r->status( 301 );
    $r->err_headers_out->add( Location => $loc );
    return 301;
  }# end unless()
  
  my ($uri, $args) = split /\?/, $new_uri;
  $r->args( split /&/, $args );
  $r->uri( $uri );
  
  return -1;
}# end handler()


sub run
{
  my ($s, $context) = @_;
  
  my $router = Router::Generic->new();
  my $routes = eval { $Config->web->routes } or return;
  eval { @$routes } or return $Response->Declined;
  map { $router->add_route( %$_ ) } @$routes;
  $Stash->{router} = $router;
  
  # Try routing:
  if( my $uri = $router->match($ENV{REQUEST_URI}) )
  {
    $Request->Reroute( $uri );
  }
  else
  {
    return $Response->Declined;
  }# end if()
}# end run()

1;# return true:

