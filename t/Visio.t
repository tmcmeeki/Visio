#!/usr/bin/perl
#
# Visio.t - test harness for Visio class.
# Revision: ___EUMM_VERSION___, Copyright (C) 2012 Thomas McMeekin
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

Visio.t - test harness for Visio class.

=head1 SYNOPSIS

perl Visio.t
[-h, --help]
[-m, --manual]

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
use Test::More tests => 33;
use Logfer qw/ :all /;

BEGIN { use_ok('Visio') };


# ---- global variables ----
my $g_log = get_logger(__FILE__);
my $re_visio = "VisioDocument.*DocumentProperties.*Pages.*VisioDocument";
my $dn_ex = "example";
my $c_this = 'Visio';


# ---- initialisation ----
chdir($dn_ex) || croak("chdir($dn_ex) failed");


# ---- new ----
my $vdx1 = Visio->new();

my $ext = $vdx1->extension;
my $fn_tpl = join('_', "$c_this", "n$ext");
my $fn0 = $fn_tpl; $fn0 =~ s/n/2/;
my $fnb = "Visio_harness" . $ext;

ok(copy($fnb, $fn0) == 1,	"setup 1");
ok(-f $fnb,			"setup 2");

$g_log->debug("fn_tpl [$fn_tpl] fn0 [$fn0] fnb [$fnb]");

my $vdx2 = Visio->new(filename => $fn0);

isa_ok( $vdx1, $c_this,	"new no parameters");
isa_ok( $vdx2, $c_this,	"new with parameters");

isa_ok($vdx1->_xml, 'Visio::XML',	"xml object 1");
isa_ok($vdx2->_xml, 'Visio::XML',	"xml object 2");


# ---- simple attributes ----
isnt($ext, "",			"extension");
isnt($vdx2->filename, "",	"filename");


# ---- list ----
ok(scalar($vdx1->list) > 0,	"list");


# ---- blank ----
isa_ok($vdx1->blank, 'XML::LibXML::Document',	"blank visio");

#$g_log->debug(sprintf 'vdx1 [%s]', Dumper($vdx1));
#$g_log->debug(sprintf '_xml [%s]', $vdx1->_xml->doc->toString);

like($vdx1->_xml->doc->toString, qr/$re_visio/,	"blank structure");
like($vdx1->_xml->doc->toString, qr/TimeCreated.*T.*TimeCreated/s,	"blank stamp");


# ---- open ----
my $fn2 = $fn_tpl; $fn2 =~ s/n/2/;

ok($vdx2->open($fn2) == 0,	"open");
like($vdx2->_xml->doc->toString, qr/$re_visio/s,	"open structure");

isa_ok($vdx2->_xml->doc, 'XML::LibXML::Document',	"doc parsed");
isa_ok($vdx2->_xml->root, 'XML::LibXML::Element',	"root parsed");

is($vdx2->_id->{'Master'}, 3,		"open id 1");
is($vdx2->_id->{'Page'}, 0,		"open id 2");
is($vdx2->_id->{'Window'}, 4,		"open id 3");

#printf "vdx2 [%s]\n", Dumper(\$vdx2);


# ---- docprop ----
for (qw/ Title Subject Creator Keywords Desc Manager Company Category /) {
	$vdx1->docprop($_, "dummy");
	like($vdx1->_xml->doc->toString, qr/$_.*dummy.*$_/s,	"docprop $_");
}

# ---- add_page ----
$vdx1->add_page("foo");
$vdx2->add_page("foo");

# ---- save ----
my $fn1 = $fn_tpl; $fn1 =~ s/n/1/;
my $vdx3 = Visio->new();
isa_ok($vdx3, $c_this,	"new no content");

ok($vdx1->save($fn1) == 0,	"save from created");
ok($vdx2->save($fn2) == 0,	"save from parse");
like($vdx2->_xml->doc->toString, qr/TimeSaved.*T.*TimeSaved/s,	"save stamp");
diag("ignore message: ERROR ... blank/open ...");
ok($vdx3->save("dummy") < 0,	"save empty");


__END__

=head1 DESCRIPTION

Test harness for the B<Visio.pm> class.

=head1 VERSION

___EUMM_VERSION___

=head1 AUTHOR

B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

