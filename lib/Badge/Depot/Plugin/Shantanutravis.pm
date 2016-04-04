use strict;
use warnings;
 
package Badge::Depot::Plugin::Shantanutravis;
 
use Moose;
use namespace::autoclean;
use Types::Standard qw/Str HashRef/;
use Path::Tiny;
use JSON::MaybeXS 'decode_json';
with 'Badge::Depot';
 
our $VERSION = '0.0202'; # VERSION
# ABSTRACT: Shantanu Bhadoria's Travis plugin for Badge::Depot based off Badge::Depot::Plugin::Travis
 
has user => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->has_meta) {
            return $self->_meta->{'username'} if exists $self->_meta->{'username'};
        }
    },
);
has repo => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my $self = shift;
        if($self->has_meta) {
            return 'perl-' . $self->get_meta->{'dist'} if exists $self->get_meta->{'dist'};
        }
    },
);
has branch => (
    is => 'ro',
    isa => Str,
    default => 'master',
);
has _meta => (
    is => 'ro',
    isa => HashRef,
    predicate => 'has_meta',
    builder => '_build_meta',
);
 
sub _build_meta {
    my $self = shift;
 
    return if !path('META.json')->exists;
 
    my $json = path('META.json')->slurp_utf8;
    my $data = decode_json($json);
 
    return if !exists $data->{'resources'}{'repository'}{'web'};
 
    my $repository = $data->{'resources'}{'repository'}{'web'};
    return if $repository !~ m{^https://(?:www\.)?github\.com/([^/]+)/(.*)(?:\.git)?$};
 
    return {
        username => $1,
        repo => $2,
    };
}
 
sub BUILD {
    my $self = shift;
    $self->link_url(sprintf 'https://travis-ci.org/%s/%s', $self->user, $self->repo);
    $self->image_url(sprintf 'https://api.travis-ci.org/%s/%s.svg?branch=%s', $self->user, $self->repo, $self->branch);
    $self->image_alt('Travis status');
}
 
1;
