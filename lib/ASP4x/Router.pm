
package ASP4x::Router;

use strict;
use warnings 'all';
use base qw( ASP4::TransHandler ASP4::RequestFilter );
use Router::Generic;
use ASP4::ConfigLoader;
use vars __PACKAGE__->VARS;

our $VERSION = '0.003';


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

=head2 In your ASP scripts and Handlers:

  <%
    # Get the router:
    my $router = $Stash->{router};
    
    # Get the uri:
    my $uri = $router->uri_for('EditPage', { type => 'truck', id => 123 });
  %>
  <a href="<%= $Server->HTMLEncode( $uri ) %>">Edit this Truck</a>

Comes out like this:

  <a href="/main/truck/123/edit/">Edit this Truck</a>

=head1 DESCRIPTION

For a gentle introduction to URL Routing in general, see L<Router::Generic>, since
C<ASP4x::Router> uses L<Router::Generic> to handle all the routing logic.

Long story short - URL Routing can help decouple the information architecture from
the actual layout of files on disk.

=head2 How does it work?

C<ASP4x::Router> uses L<Router::Generic> for the heavy lifting.  It functions as
both a mod_perl C<PerlTransHandler> and as a L<ASP4::RequestFilter>, providing the
same exact routing behavior for both L<ASP4::API> calls and for normal HTTP requests
handled by the mod_perl interface of your web server.

When a request comes in to Apache, mod_perl will know that C<ASP4x::Router> might
make a change to the URI - so it has C<ASP4x::Router> take a look at the request.  If
any changes are made (eg - C</foo/bar/1/> gets changed to C</pages/baz.asp?id=1>)
then the server handles the request just as though C</pages/baz.asp?id=1> had been
requested in the first place.

For testing - if you run this:

  $api->ua->get('/foo/bar/1/');

C<ASP4x::Router> will "reroute" that request to C</pages/baz.asp?id=1> as though you
had done it yourself like this:

  $api->ua->get('/pages/baz.asp?id=1');

=head2 What is the point?

Aside from the "All the cool kids are doing it" argument - you get super SEO features
and mad street cred - all in one shot.

Now, instead of 1998-esque urls like C</page.asp?category=2&product=789&revPage=2> you get
C</shop/marbles/big-ones/reviews/page/4/>

=head2 What about performance?

Unless you have literally B<*thousands*> of different entries in the "C<routing>"
section of your C<conf/asp4-config.json> file, performance should be B<quite> fast.

=head2 Where can I learn more?

Please see the documentation for L<Router::Generic> to learn all about how to 
specify routes.

=head1 PREREQUISITES

L<ASP4>, L<Router::Generic>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the same terms as any version of Perl itself.

=cut

