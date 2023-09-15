#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use OPC;

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
	
	if ($pt =~ /relationships/) {

#		if ($pn eq '/_rels/.rels') {
#			print "SKIPPING [$pn]\n";
#		} else {
			for ($doc->Relations($pn, 'type' => $pt)) {
				printf "XXX relation [%s]\n", Dumper($_);
			}
#		}
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
