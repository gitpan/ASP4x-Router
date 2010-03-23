
package ASP4x::Router;

use strict;
use warnings 'all';
use base qw( ASP4::TransHandler ASP4::RequestFilter );
use Router::Generic;
use ASP4::ConfigLoader;
use vars __PACKAGE__->VARS;

our $VERSION = '0.001';


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
  
  my $new_uri = $router->match( $r->uri . ( $r->args ? '?' . $r->args : '' ), $r->method )
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
  if( my $uri = $router->match( $ENV{REQUEST_URI}, $ENV{REQUEST_METHOD} ) )
  {
    $Request->Reroute( $uri );
  }
  else
  {
    return $Response->Declined;
  }# end if()
}# end run()

1;# return true:

=pod

=head1 NAME

ASP4x::Router - URL Routing for your ASP4 web application.

=head1 SYNOPSIS

=head2 httpd.conf

  <Perl>
    push @INC, '/path/to/yoursite.com/lib';
  </Perl>
  
  PerlModule ASP4x::Router
  
  ...
  
  <VirtualHost *:80>
  ...
    PerlTransHandler ASP4x::Router
  ...
  </VirtualHost>

=head2 asp4-config.json

  ...
  "web": {
    ...
    "request_filters": [
      ...
      {
        "uri_match": "/.*",
        "class":     "ASP4x::Router"
      }
      ...
    ]
    ...
    "routes": [
      {
        "name":   "CreatePage",
        "path":   "/main/:type/create",
        "target": "/pages/create.asp",
        "method": "GET"
      },
      {
        "name":   "Create",
        "path":   "/main/:type/create",
        "target": "/handlers/dev.create",
        "method": "POST"
      },
      {
        "name":   "View",
        "path":   "/main/:type/{id:\\d+}",
        "target": "/pages/view.asp",
        "method": "*"
      },
      {
        "name":   "EditPage",
        "path":   "/main/:type/{id:\\d+}/edit",
        "target": "/pages/edit.asp",
        "method": "GET"
      },
      {
        "name":   "Edit",
        "path":   "/main/:type/{id:\\d+}/edit",
        "target": "/handlers/dev.edit",
        "method": "POST"
      },
      {
        "name":     "List",
        "path":     "/main/:type/list/{page:\\d*}",
        "target":   "/pages/list.asp",
        "method":   "*",
        "defaults": { "page": 1 }
      },
      {
        "name":   "Delete",
        "path":   "/main/:type/{id:\\d+}/delete",
        "target": "/handlers/dev.delete",
        "method": "POST"
      }
    ]
    ...
  }
  ...



=head1 DESCRIPTION

For a gentle introduction to URL Routing in general, see L<Router::Generic>, since
C<ASP4x::Router> uses L<Router::Generic> to handle all the routing logic.

URL Routing is the best thing since sliced bread.  Routing has been approved by the FDA to:

=over 4

=item * Slice!

=item * Dice!

=item * Do your dishes!

=item * Kill mice!

=back

URL Routing is also a cure for the poorly-constructed URL.

=head1 PREREQUISITES

L<ASP4>, L<Router::Generic>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the same terms as any version of Perl itself.

=cut

