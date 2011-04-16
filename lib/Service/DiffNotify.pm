package Service::DiffNotify;
use 5.008_001;
use Mouse;

our $VERSION = '0.01';

use Algorithm::Diff;
use Filesys::Notify::Simple;
use Growl::Any;

#use Text::Extract::Word;

has dir => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
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
        return Growl::Any->new(__PACKAGE__, ['chnaged']);
    },
    lazy     => 1,
);

has ignore_files => (
    is       => 'rw',
    isa      => 'ArrayRef',
    default  => sub {
        return [
            qr/ \. (?: sw[px] | old | bak) \z/xms,
            qr/     ~  \z     /xms,
            qr{  [/\\] \.git  }xms,
            qr/     \d \z     /xms, # vim working files
        ];
    },
);

sub in_ignore_files {
    my($self, $path) = @_;

    foreach my $rx(@{ $self->ignore_files }) {
        return 1 if $path =~ $rx;
    }
    return 0;
}

sub run {
    my($self) = @_;

    $self->watcher->wait(sub {
        foreach my $event(@_) {
            my $path = $event->{path};
            next if $self->in_ignore_files($path);

            $self->notify(changed => 'File changed', $path);
        }
    }) while 1;

}

no Mouse;
1;
__END__

=head1 NAME

Service::DiffNotify - Growl for changed files

=head1 VERSION

This document describes Service::DiffNotify version 0.01.

=head1 SYNOPSIS

    use Service::DiffNotify;

    Service::DiffNotify->new(dir => '.')->run();

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

# TODO

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
