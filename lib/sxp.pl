#!/usr/bin/perl
use strict;
use warnings;
#
# PROGRAM: sxp.pl
# DESCR:   This program uses my simpleXMLParse.pm module
#          to take as input an XML file, parse style
#          and prints to STDOUT a Perl HASH (Dumper)
#          representing this parse.
# v. 1.0, Daniel Edward Graham, 10/10/2012
# LGPL 3.0
# 
# Usage: sxp.pl <inputfile> <parsestyle>
#
# <inputfile> ::= the xml file to parse
# <parsestyle> ::= 1 or 2 (optional)
#
use simpleXMLParse;
use Data::Dumper;

my $fn = $ARGV[0];
my $style = $ARGV[1];

my $parse = new simpleXMLParse({input => $fn, style => $style});

print Dumper($parse->parse());


