#!/usr/bin/perl

package Callback::Cleanup;

use strict;
use warnings;

use B qw(svref_2object CVf_CLONED);

use Sub::Exporter -setup => {
	exports => [qw(cleanup callback)],
	groups  => { default => [":all"] },
};

our $VERSION = "0.02";

sub cleanup (&;$) {
	my ( $cleanup, $sub ) = @_;
	$sub ? __PACKAGE__->new( $sub, $cleanup ) : $cleanup;
}

sub callback (&;$) {
	my ( $sub, $cleanup ) = @_;
	$cleanup ? __PACKAGE__->new( $sub, $cleanup ) : $sub;
}

sub new {
	my ( $class, $body, $cleanup ) = @_;

	if ( svref_2object($body)->CvFLAGS & CVf_CLONED ) {
		Callback::Cleanup::Closure->new($body, $cleanup);
	} else {
		Callback::Cleanup::Array->new($body, $cleanup);
	}
}

{
	package Callback::Cleanup::Base;

	sub DESTROY { $_[0]->cleanup }
}

{
	package Callback::Cleanup::Closure;
	use base qw(Callback::Cleanup::Base);

	use Hash::Util::FieldHash::Compat qw(fieldhash);

	use namespace::clean;

	fieldhash my %cleanups;

	sub new {
		my ( $pkg, $sub, $cleanup ) = @_;
		$cleanups{$sub} = $cleanup;
		bless $sub, $pkg;
	}

	sub cleanup { $cleanups{$_[0]}->() }
}

{
	package Callback::Cleanup::Array;
	use base qw(Callback::Cleanup::Base);

	use overload '&{}' => sub { $_[0]{body} };

	sub new {
		my ( $pkg, $sub, $cleanup ) = @_;
		bless { body => $sub, cleanup => $cleanup }, $pkg;
	}

	sub cleanup { $_[0]{cleanup}->() }
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

=head1 CLOSURES AND GARBAGE COLLECTION

In perl code references that are not closures aren't garbage collected (they
are shared).

In order to make those still work Callback::Cleanup wraps them in a simple
overloading object.

You can avoid this workaround by always ensuring the objects you pass in
always close over something.

Note that this will bless your closures, and you can't have more than one
cleanup sub associated with a closure.

If you want to force one behavior or another, use L<Callback::Cleanup::Closure>
or L<Callback::Cleanup::Array> directly:

	Callback::Cleanup::Closure->new(
		\&foo,
		sub { warn "this is probably global destruction" },
	);

	Callback::Cleanup::Array->new(
		sub { $closure_var }, # avoids blessing this by wrapping instead
		sub { ... },
	);

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2006, 2008 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


