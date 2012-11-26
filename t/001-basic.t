#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Middleware::Static;

use Data::Dumper;

BEGIN {
    use_ok('Plack::Middleware::TypeScript');
}

my $output = q{var Hello = (function () {
    function Hello() { }
    Hello.prototype.world = function () {
        return "Hello World";
    };
    return Hello;
})();
var hello = new Hello();
window.alert(hello.world());
};

{
    my $app = Plack::Middleware::TypeScript->wrap(
        Plack::Middleware::Static->new( 
            path => qr{\.js$}, 
            root => '.'
        ),
        root => '.',
        path => qr{\.js$},     
    );

    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;
            {
                my $req = HTTP::Request->new(GET => "http://localhost/t/test/hello.js");
                my $res = $cb->($req);
                my $content = $res->content;
                $content =~ s/\r\n/\n/g;
                is( $content, $output, '... got the compiled javascript we expected');
            }
        };


    unlink 't/test/hello.js';
}

{
    my $app = Plack::Middleware::TypeScript->wrap(
        Plack::Middleware::Static->new( 
            path => sub { s!^/static/!/t/test/! }, 
            root => '.'
        ),
        root => '.',
        path => sub { s!^/static/!/t/test/! },     
    );

    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;
            {
                my $req = HTTP::Request->new(GET => "http://localhost/static/hello.js");
                my $res = $cb->($req);
                my $content = $res->content;
                $content =~ s/\r\n/\n/g;
                is( $content, $output, '... got the compiled javascript we expected');
            }
        };

    unlink 't/test/hello.js';

}

done_testing;


