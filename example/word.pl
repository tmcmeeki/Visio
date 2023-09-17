#!/usr/bin/perl

use warnings;
use strict;

use Document::OOXML;

#my $pnv = "Visio_harness.vsdx";
my $pnv = "Word_harness.docx";

printf "opening [$pnv]\n";

my $doc = Document::OOXML->read_document($pnv);

