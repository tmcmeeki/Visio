package Visio;
# $Header: /home/tomby/RCS/Visio.pm,v 1.6 2010/08/02 00:41:48 tomby Exp $
#
# Visio.pm - revised class for Visio.
# $Revision: 1.6 $, Copyright (C) 2010 Thomas McMeekin
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#
# History:
# $Log: Visio.pm,v ___join_line_here___ $

=head1 NAME

Visio - revised class for Visio.

=head1 SYNOPSIS

	use Visio;


=head1 DESCRIPTION

___detailed_class_description_here___

=over 4

=item 1.  tba

tba

=back

=cut

use strict;

use vars qw/ $VERSION /;
#use vars qw/ @ISA $VERSION /;

use Carp qw(cluck confess); # only use stack backtrace within class
use Data::Dumper;

use File::Basename;
use POSIX;
use Visio::XML;
use Logfer qw/ :all /;


# package constants

use constant EXT_DOCUMENT  => ".vdx";

use constant NN_DOCUMENT => "VisioDocument";

use constant NN_SECTIONS => qw/ DocumentProperties DocumentSettings Colors
  FaceNames StyleSheets DocumentSheet Masters Pages Windows /;


# package globals
our $AUTOLOAD;
$VERSION = "1.001";     # update this on new release
#@ISA = ( "XML" );
#@EXPORT = qw();


# package locals
my $_n_objects = 0;	# counter of objects created.

my %attribute = (
	_n_objects => \$_n_objects,
	_log => get_logger("Visio"),
	extension => EXT_DOCUMENT,
	dir => ".",
	filename => undef,
	fho => \*STDOUT,
	_id => {	# see open()
		'Shape' => 1,
		'Master' => 0,
		'Page' => 0,
		'Window' => 0,
	},
	_loaded => 0,	# flag shows if a document is in-memory
	_xml => undef,
);


#INIT { };


sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or croak("self is not an object");

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully−qualified portion

	unless (exists $self->{_permitted}->{$name} ) {
		confess "no attribute [$name] in class [$type]";
	}

	if (@_) {
		return $self->{$name} = shift;
	} else {
		return $self->{$name};
	}
}


sub new {
	my ($class,%h_args) = shift;
#	my $self = $class->SUPER::new(%h_args);
#        foreach my $attr (keys %attribute) {
#		$self->{_permitted}->{$attr} = $attribute{$attr};
#	}
#	@{$self}{keys %attribute} = values %attribute;
	my $self = { _permitted => \%attribute, %attribute };

	++ ${ $self->{_n_objects} };

	bless ($self, $class);

	my %args = @_;	# start processing any parameters passed
	my ($method,$value);
	while (($method, $value) = each %args) {

		confess "SYNTAX new(method => value, ...) value not specified"
			unless (defined $value);

		$self->$method($value);
	}

	$self->{_xml} = Visio::XML->new;

	return $self;
}


sub list {
#	LIST directory contents for matching files!
	my $self = shift;
	my $dir = shift;

	if (defined $dir) {
		chdir($dir) || confess("chdir($dir) failed");
		$self->dir($dir);
	}

	my @files = glob('*' . $self->extension);

	$self->_log->debug(sprintf '@files [%s]', Dumper(\@files));

	return @files;
}


sub edit {
	my $self = shift;

	$self->docprop("TimeEdited", $self->timestamp);
}


sub empty {
	my $self = shift;

	$self->_log->logwarn("ERROR no document to save; have you done a blank() or open()?");

	return -1;
}


sub add_page {
	my $self = shift;
	my $name = shift;

	confess "SYNTAX add_page(name)" unless (defined $name);

	return $self->empty
		unless ($self->_loaded);

	$self->edit;

	my $type = 'Page'; 
	my ($top,undef) = $self->_xml->find($self->_xml->root, "$type" . "s");
	my ($page,undef) = $self->_xml->create($top, $type);

	$page->setAttribute('ID', ++$self->_id->{$type});
	$page->setAttribute('NameU', $name);

	return $name;
}


sub docprop {
	my $self = shift;
	my $prop = shift;
	my $value = shift;

	confess "SYNTAX docprop(property, [value])" unless (defined $prop);

	return $self->empty
		unless ($self->_loaded);

	if (defined $value) {
		$self->_xml->set_property("DocumentProperties", $prop, $value);
	}

	return $value;
}


sub blank {
	my $self = shift;

	my $doc = $self->_xml->prepare(NN_DOCUMENT, NN_SECTIONS);

	$self->_loaded(1);

	$self->docprop("TimeCreated", $self->timestamp);

	return $doc;
}


sub open {
	my $self = shift;
	if (@_) { $self->filename(shift); }

	confess("SYNTAX open(filename)")
		unless defined($self->filename);

	confess(sprintf "file not found [%s]", $self->filename)
		unless (-f $self->filename);

	if ($self->_xml->read($self->filename) eq NN_DOCUMENT) {

		$self->_loaded(1);

		# observed business rules
		#	Shape ID starts at 1
		#	Master ID orders 0, 2, 3, ...
		#	Shape ID in master >= 4
		#	Page ID starts at 0
		#	Window ID starts at 0

		for (qw/ Master Page Window /) {
			my ($top,undef) = $self->_xml->find($self->_xml->root, $_ . 's');
			my (undef,$id) = $self->_xml->find($top, $_);

			$self->_id->{$_} = $id;
		}

		return 0;
	}

	return -1;
}


sub save {
	my $self = shift;
	if (@_) { $self->filename(shift); }

	confess("SYNTAX save(filename)")
		unless defined($self->filename);

	return $self->empty
		unless ($self->_loaded);

	$self->docprop("TimeSaved", $self->timestamp);

	unless ($self->_xml->write($self->filename)) {

		return 0
			if (-f $self->filename);
	}

	$self->_log->warn(sprintf "file not written [%s]", $self->filename);

	return -1;
}


sub timestamp {
	my $self = shift;
	my $value = shift;	# in format expected by time()

	$value = time
		unless(defined $value);

	my $stamp = POSIX::strftime("%Y-%m-%dT%H:%M:%S", localtime($value));

	$self->_log->debug("returning [$stamp]");

	return $stamp;
}


DESTROY {
	my $self = shift;

	-- ${ $self->{_n_objects} };
};

#END { }

1;

__END__

=head1 VERSION

$Revision: 1.6 $

=head1 AUTHOR

Copyright (C) 2010  Tom McMeekin

=head1 SEE ALSO

L<perl>.

=cut

