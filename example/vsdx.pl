#!/usr/bin/perl

use warnings;
use strict;

# ref. https://learn.microsoft.com/en-us/office/client-developer/visio/how-to-manipulate-the-visio-file-format-programmatically
# ref. https://stackoverflow.com/questions/59935217/xmllibxml-issue-finding-xml-nodes-with-a-namespace

use Data::Dumper;
use OPC;
use XML::LibXML;
use XML::LibXML::PrettyPrint;

use constant NS_OPC => "http://schemas.openxmlformats.org/package/2006/relationships";

sub put_node {
	my $node = shift;

	printf "find [%s]  ", $node->getName;
	printf "nodeName [%s]  ", $node->nodeName;
	printf "localname [%s]  ", $node->localname;
#	printf "to_literal [%s]  ", $node->to_literal;

	my ($name, $value); for my $ns ($node->getNamespaces) {
		printf "name [%s]  ", $ns->name;
		printf "getPrefix [%s]  ", $ns->getPrefix;
		printf "value [%s]  ", $ns->value;

		$name = $ns->name;
		$value = $ns->value;

		last;
	}

	printf "\n";

	return ($name, $value);
}

my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");

my $pnv = "Visio_harness.vsdx";

printf "opening [$pnv]\n";

my $doc = OPC->new($pnv);

printf "ref(doc) = [%s]\n", ref($doc);

#printf "root = [%s]\n", Dumper($doc->Root);

printf "IsBinary = [%s]\n", $doc->IsBinary;

printf "\n";
printf "PartNames\t  PartContentType\n";
#printf "PartNames [%s]\n", join(' ', $doc->PartNames);
my %pct; for my $pn ($doc->PartNames) {

	my $pt =  $doc->PartContentType($pn);

	printf "$pn\t  $pt\n";

	if (exists $pct{$pt}) {
		push @{ $pct{$pt} }, $pn;
	} else {
		$pct{$pt} = [ $pn ];
	}

	my $xml = $doc->PartContents($pn);
#	print "  PartContents [$xml]\n";
	my $dom = XML::LibXML->load_xml(string => $xml);
	$pp->pretty_print($dom);
	print $dom->toString;

#	for ($dom->findnodes('//@*')) {
#		printf "attr [%s]\n", $_->getName;
#	}

	for ($dom->findnodes('*')) {
		my ($nsn, $nsu) = put_node($_);

		my $this = $_->getName;
		printf "ELEMENT [$this]\n";

		my $xpc = XML::LibXML::XPathContext->new($dom);

		printf "\nregistering namespace [$nsn] for [$nsu]\n";
		$xpc->registerNs($nsn, $nsu);

		my $xp = sprintf "//$nsn:*"; printf "xp [$xp]\n";
		for ($xpc->findnodes($xp)) {
			put_node($_);

			for my $attr ($_->attributes) {

				my $atn = $attr->getName;
				my $atv = $attr->getValue;

				printf "attribute [$atn] = [$atv]\n";

				next unless ($this eq "Relationships");

				my $which = (); if ($atn eq 'Type') {
					$which = 'type';
				} elsif ($atn eq 'Id') {
					$which = 'id';
				} else {
					print "skipping irrelevant attribute\n";
				}
				if (defined $which) {

					print "polling relationships [$which]=[$atv]\n";

					for ($doc->Relations($pn, $which => $atv)) {
						printf "XXX $which relation [%s]\n", Dumper($_);
					}
				}
			}
		}
	}

	printf "\n";
}
printf "pct [%s]\n", Dumper(\%pct);

__END__

for ($doc->RelationNodesFromDoc('/visio/pages/_rels/pages.xml.rels')) {
	printf "RelationNodesFromDoc [%s]\n", Dumper($_);
}
for ($doc->RelationsByType('/visio/pages/_rels/pages.xml.rels')) {
	printf "RelationsByType [%s]\n", Dumper($_);
}
