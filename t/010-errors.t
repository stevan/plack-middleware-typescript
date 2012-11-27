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

my $output = q{TypeScript compilation failed:
CMD: tsc --out ./t/test/bad.js ./t/test/bad.tsERR: /Users/stevan/Desktop/Plack-Middleware-TypeScript/t/test/bad.ts (1,6): Expected ';'

/usr/local/lib/node_modules/typescript/bin/tsc.js:24386
                    throw err;
                          ^
TypeError: Cannot call method 'Close' of null
    at TypeScriptCompiler.emit (/usr/local/lib/node_modules/typescript/bin/tsc.js:23356:25)
    at BatchCompiler.compile (/usr/local/lib/node_modules/typescript/bin/tsc.js:24382:26)
    at BatchCompiler.batchCompile (/usr/local/lib/node_modules/typescript/bin/tsc.js:24671:18)
    at Object.<anonymous> (/usr/local/lib/node_modules/typescript/bin/tsc.js:24680:7)
    at Module._compile (module.js:449:26)
    at Object.Module._extensions..js (module.js:467:10)
    at Module.load (module.js:356:32)
    at Function.Module._load (module.js:312:12)
    at Module.require (module.js:362:17)
    at require (module.js:378:17)
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
                my $req = HTTP::Request->new(GET => "http://localhost/t/test/bad.js");
                my $res = $cb->($req);
                is( $res->code, 500, '... got the error we expected' );
                is( $res->content, $output, '... got the compiled javascript we expected');
            }
        };

}

done_testing;


