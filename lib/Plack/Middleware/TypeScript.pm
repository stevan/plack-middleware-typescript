package Plack::Middleware::TypeScript;
use Moose;
use MooseX::NonMoose;
use MooseX::Types::Path::Class;

use Plack::Request;

extends 'Plack::Middleware';

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
    my $self = shift;
    my $req  = Plack::Request->new( shift );
    my $path = $req->path_info;
    $path =~ s/^\///;

    if ( $self->is_javascript_file( $path ) ) {
        #warn "Got a JS file";
        if ( $self->does_equivalent_typescript_file_exist( $path ) ) {
            #warn "Found a matching TS file";
            if ( $self->is_in_cache( $path ) ) {
                #warn "We are in the cache";
                if ( $self->mtime( $path ) ne $self->fetch_from_cache( $path ) ) {
                    #warn "And we need a recompile";
                    $self->compile_typescript_file_to_javascript( $path );
                }
            }
            else {
                #warn "We are not in the cache";
                $self->add_to_cache( $path, $self->mtime( $path ) );
                $self->compile_typescript_file_to_javascript( $path );
            }    
        }

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
    #warn $ts_file;
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

    #warn "Compiling $path ...";

    system( 'tsc', '--out', $path, $self->get_typescript_file_from_javascript_file( $path ) );
}

1;

__END__

=pod

=cut
