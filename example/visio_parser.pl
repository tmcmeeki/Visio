#!/usr/bin/perl
#
# visio_parser.pl - summarise elements and attributes for a Visio XML diagram
# Revision ___EUMM_VERSION___, Copyright (C) 2014 Thomas McMeekin
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
=head1 NAME

visio_parser.pl - summarise elements and attributes for a Visio XML diagram

=head1 SYNOPSIS

perl -I ../lib -I ../../Visio-XML/lib -w visio_parser.pl 

[-h, --help]
[-m, --manual]
file ...

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--manual>

Prints the manual page and exits.

=back

=cut

use strict;

use Carp qw/ croak carp /; 
use Data::Dumper;

use Cwd;
use File::Copy;;
use Logfer qw/ :all /;

use Visio;
use XML::LibXML qw/ :libxml /;


# ---- global variables ----
my $g_log = get_logger(__FILE__);
my %g_xml;


# ---- initialisation ----
#printf "argv [%s]\n", scalar @ARGV;
die "usage: perl -I ../lib -I ../../Visio-XML/lib -w visio_parser.pl file ...\n" if (@ARGV < 1);
my $vdx = Visio->new();


# ---- sub-routines ----
sub blank {
	my ($value)=@_;
	my $blank = "(blank)";

	return $blank unless (defined $value);

	$g_log->debug("before value [$value]");

	$value =~ s/^\s*$//g;

	$g_log->debug(" after value [$value]");

	return $blank
		if ($value eq '');

	return $value;
}


sub offset {
	my $level = shift;

	my $tab = "";

	while (--$level >= 0) {

		$tab .= "    ";
	}

	return $tab;
}


sub record {
	my ($key, $value)=@_;

	chomp $value;

	if (exists $g_xml{$key}) {

		if (exists $g_xml{$key}->{$value}) {

			$g_xml{$key}->{$value}++;
		} else {
			$g_xml{$key}->{$value} = 1;
		}
	} else {

		$g_xml{$key} = { $value => 1 };
	}
}


sub whatami {
	my ($xpath,$node,$level)=@_;

	return -1 unless defined ($node);

	my $type = $node->nodeType;
	my $name = blank($node->nodeName);
	my $s_type;
	my $value = "";

	if ($type == XML_ELEMENT_NODE) {
		$s_type = "element";
		$value = blank($node->nodeValue);

	} elsif ($type == XML_ATTRIBUTE_NODE) {
		$s_type = "attr";
		$value = blank($node->getValue);

		my $key = join('@', $xpath, $name);
		record($key, $value);

	} elsif ($type == XML_TEXT_NODE) {
		$s_type = "text";
		$value = blank($node->nodeValue);

		$value = 'XXXXX' if ($xpath =~ /\/PreviewPicture|\/Icon/);

		record($xpath, $value);

	} elsif ($type == XML_COMMENT_NODE) {

		$s_type = "comment";

	} else {
		$s_type = "other";
	}
	$g_log->debug(sprintf "%stype '%s(%s)' path '%s' name '%s' %s", offset($level), $s_type, $type, $xpath, $name, ($value eq "") ? "" : sprintf('value [%s]', $value));

	return $type;
}


sub recurse {
	my ($parent,$level,$path)=@_;

	my $xpath = join('/', $path, $parent->nodeName);

	$g_log->debug("xpath [$path]");

	whatami($xpath, $parent, $level);

	for ($parent->attributes()) {

		whatami($xpath, $_, $level);

		#$g_log->debug(sprintf "%s type [%s] attr [%s] value [%s]", offset($level), $_->nodeType, $_->nodeName, blank($_->getValue));
	}

	my $children = 0;
	for ($parent->childNodes) {
		$g_log->debug(sprintf("%schild [%s]", offset($level), $children++));
		recurse($_, $level+1, $xpath);
	}
}


# ---- main ----
for my $m_fn (@ARGV) {

	next if ($vdx->open($m_fn));

	#$g_log->debug(sprintf 'XML [%s]', Dumper($vdx->_xml));


	#$g_log->debug(sprintf 'nodes [%s]', Dumper(\@nodes));

	recurse($vdx->_xml->root, 0, "");
}

# dump values
$g_log->info("listing of values");
$g_log->info("path\texample value(s)");

for my $xpath (sort(keys %g_xml)) {

	$g_log->info(sprintf "%s:\t%s",
		$xpath,
		join(', ', sort(keys %{ $g_xml{$xpath} }))
	);
}


__END__

=head1 DESCRIPTION

Parse Visio XML diagram and summarise elements and attributes.

=head1 VERSION

___EUMM_VERSION___

=head1 AUTHOR

B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

