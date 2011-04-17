package Service::DiffNotify;
use 5.008_001;
use Mouse;

our $VERSION = '0.01';

use Algorithm::Diff qw(diff);
use Filesys::Notify::Simple;
use Growl::Any;
use File::Find qw(find);
use File::Spec;
use Text::Extract::Word;
use Encode qw(decode);
use Encode::Guess qw(euc-jp shiftjis 7bit-jis);

use Log::Minimal qw(infof warnf debugf);

my %ft_map = ( # file type mapping
    (map { $_ => 'text' }
        qw(
            .txt .html .htm .xml .css .js
            .tx .tt .tmpl .tpl
            .pl .pm .pod .xs .ep
            .rb .erb .py  .php
            .hs .c .cpp .cxx .h .hpp .hxx

           readme changes changelog install makefile
        )
    ),

    '.doc' => 'word',
);

has dir => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has snapshot => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef,
);

has watcher => (
    is       => 'rw',
    isa      => 'Object',
    default  => sub {
        my($self) = @_;
        return Filesys::Notify::Simple->new([ $self->dir ]);
    },
    lazy => 1,
);

has growler => (
    is       => 'ro',
    isa      => 'Object',
    handles  => [qw(notify)],
    default  => sub {
        return Growl::Any->new(
            appname => __PACKAGE__,
            events  => ['changed']);
    },
    lazy     => 1,
);

sub run {
    my($self) = @_;

    $self->make_snapshot( $self->dir );

    infof 'watching';
    $self->watcher->wait(sub {
        foreach my $event(@_) {
            my $path = $event->{path};
            my $diff = $self->changed($path) or next;

            infof 'changed: %s', $path;
            $self->notify(changed => File::Spec->abs2rel($path), $diff);
        }
    }) while 1;

}

sub guess_file_type {
    my($self, $path) = @_;
    foreach my $pat(keys %ft_map) {
        if( $path =~ / \Q$pat\E  \z/xmsi ) {
            return $ft_map{$pat};
        }
    }
    return undef;
}

sub make_snapshot {
    my($self, $dir) = @_;
    my $snapshot = {};
    infof 'make_snapshot: %s', $dir;
    find sub {
        return if -d $_;
        my $type = $self->guess_file_type($_) or return;
        debugf '%s: %s', $type, $_;

        my $file = File::Spec->rel2abs($_);
        $snapshot->{ $file } = [ $type, $self->slurp($file, $type) ];
        return;
    }, $dir;
    $self->snapshot($snapshot);
    return;
}

sub slurp {
    my($self, $file, $type) = @_;

    return '' unless -s $file;

    if($type eq 'word') {
        return eval {
            my $doc = Text::Extract::Word->new($file);
            return $doc->get_body();
        } || '';
    }
    else { # text
        open my $slurp, '<:raw', $file
            or warnf('Cannot open %s for reading: %s', $file, $!), return '';
        local $/;
        return decode( guess => <$slurp> );
    }
}

sub changed {
    my($self, $file) = @_;

    $file = File::Spec->rel2abs($file);
    my $old = $self->snapshot->{$file} or return;
    my($type, $old_content) = @{$old};
    my $cur_content         = $self->slurp($file, $type);

    return if $cur_content eq ''; # workaround vim's empty files
    return if $old_content eq $cur_content;

    $self->snapshot->{$file}[1] = $cur_content; # update

    return $self->do_diff($old_content, $cur_content);
}


sub do_diff { # (self, old, new)
    my $self = shift;
    my @x = split /\n/, shift;
    my @y = split /\n/, shift;

    my $diffs = diff(\@x, \@y);

    my $s = '';
    foreach my $diff(@{$diffs}) {
        foreach my $d(@{$diff}) {
            my($status, $line, $content) = @{$d};
            next if $status ne '+'; # keep it simple
            $content =~ s/\A \s+ //xms; # trim
            $s .= sprintf "%03d:\n%s\n", $line, $content;
        }
    }
    return $s;
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Service::DiffNotify - Watch a directory and make notifications on changes

=head1 VERSION

This document describes Service::DiffNotify version 0.01.

=head1 SYNOPSIS

    use Service::DiffNotify;

    Service::DiffNotify->new(dir => '.')->run();

    # or type `niff .`

=head1 DESCRIPTION

This module provides a service which watches a directory and makes
notifications on changes as growls.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Filesys::Notify::Simple>

L<Growl::Any>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
