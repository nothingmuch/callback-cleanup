#!/usr/bin/perl

package Callback::Cleanup;

use strict;
use warnings;

use base qw/Exporter/;
BEGIN { our @EXPORT = qw/cleanup callback/ }

our $VERSION = "0.01";

use overload '&{}' => sub { $_[0][0] };

sub new {
	my ( $pkg, $sub, $cleanup ) = @_;
	bless [ $sub, $cleanup ], $pkg;
}

sub DESTROY { $_[0][1]->() }

sub cleanup (&;$) {
	my ( $cleanup, $sub ) = @_;
	$sub ? __PACKAGE__->new( $sub, $cleanup ) : $cleanup;
}

sub callback (&;$) {
	my ( $sub, $cleanup ) = @_;
	$cleanup ? __PACKAGE__->new( $sub, $cleanup ) : $sub;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Callback::Cleanup - Declare callbacks that clean themselves up

=head1 SYNOPSIS

	use Callback::Cleanup;

	my $anon_sub = callback {
		# this is the sub body
	} cleanup {
		# this is called on DESTROY
	}

	# or

	Callback::Cleanup->new(
		sub { }, # callback
		sub { }, # cleanup
	);

=head1 DESCRIPTION

This is a very simple module that provides syntactic sugar for callbacks that
need to finalize somehow.

Callbacks are very convenient APIs when they have no definite end of life. If
an end of life behavior is required this helps keep the cleanup code and
callback code together.

=head1 EXPORTS

=over 4

=item callback BLOCK $cleanup

=item cleanup BLOCK $callback

Both of these exports act as the identity function when given only one
parameter.

When given enough arguments they will create a Callback::Cleanup object.

This means that you can declare a callback with a cleanup like this:

	my $cleans_up = callback {

	} cleanup {
	
	}

Or a derived sub that cleans up an existing subref:

	my $cleans_up = cleanup {

	} \&needs_cleanup;

As well as a few other useless forms.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2006 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


