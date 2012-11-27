package Plack::Middleware::TypeScript;
use Moose;
use MooseX::NonMoose;
use MooseX::Types::Path::Class;

use Capture::Tiny qw[ capture ];
use Plack::Request;

extends 'Plack::Middleware';

has 'root' => (
    is       => 'ro',    
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1
);

has 'path' => (
    is       => 'ro',    
    isa      => 'RegexpRef | CodeRef',
    required => 1
);

has 'cache' => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
    handles => {
        'is_in_cache'      => 'exists',
        'fetch_from_cache' => 'get',
        'add_to_cache'     => 'set',
    }
);

sub call {
    my $self    = shift;
    my $req     = Plack::Request->new( shift );
    my $path    = $req->path_info;
    my $matcher = $self->path;

    for ($path) {
        my $matched = ref $self->path eq 'CODE' ? $matcher->( $_ ) : $_ =~ $matcher;
        return unless $matched;
    }
    $path = $self->root->stringify . $path;

    my $error;

    if ( $self->is_javascript_file( $path ) ) {
        if ( $self->does_equivalent_typescript_file_exist( $path ) ) {
            if ( $self->is_in_cache( $path ) ) {
                if ( $self->mtime( $path ) ne $self->fetch_from_cache( $path ) ) {
                    $error = $self->compile_typescript_file_to_javascript( $path );
                }
            }
            else {
                $error = $self->compile_typescript_file_to_javascript( $path );
            }    
        }
    }

    if ( $error ) {
        $req->logger->({ level   => 'error', message => $error }) if $req->logger;
        my $res = $req->new_response( 500 );
        $res->body([ $error ]);
        return $res->finalize;
    } else {
        $self->add_to_cache( $path, $self->mtime( $path ) );
    }

    $self->app->( $req->env );
}

sub is_javascript_file {
    my ($self, $path) = @_;
    $path =~ /\.js$/;
}

sub get_typescript_file_from_javascript_file {
    my ($self, $path) = @_;
    my $ts_file = $path;
    $ts_file =~ s/\.js$/\.ts/;
    $ts_file;
}

sub does_equivalent_typescript_file_exist {
    my ($self, $path) = @_;
    -f $self->get_typescript_file_from_javascript_file( $path )
}

sub mtime {
    my ($self, $file) = @_;
    return join ' ', ( stat( $file ) )[ 1, 7, 9 ];
}

sub compile_typescript_file_to_javascript {
    my ($self, $path) = @_;

    my @cmd = ('tsc', '--out', $path, $self->get_typescript_file_from_javascript_file( $path ));
    my ($stdout, $stderr, $exit) = capture { system( @cmd ) };

    if ( $exit != 0 ) {
        $stderr =~ s/\r\n/\n/g;
        return "TypeScript compilation failed:\n" 
            .  "CMD: " . (join ' ' => @cmd)
            .  "ERR: " . $stderr;
    }
    
    return;
}

1;

__END__

=pod

=cut
