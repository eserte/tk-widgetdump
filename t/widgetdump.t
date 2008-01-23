#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: widgetdump.t,v 1.9 2008/01/23 21:51:26 eserte Exp $
# Author: Slaven Rezic
#

use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip: no Test::More module\n";
	exit;
    }
}

my $real_tests = 1;
plan tests => 1 + $real_tests;

use Tk;
use Tk::DragDrop;
use Tk::DropSite;

$ENV{BATCH} = 1 if !defined $ENV{BATCH};

use_ok('Tk::WidgetDump');

my $top = eval { tkinit };
if (!$top) {
 SKIP: { skip("Cannot create MainWindow", $real_tests) }
    exit 0;
}

$top->gridRowconfigure($_, -weight => 1) for (0..4);
$top->gridColumnconfigure($_, -weight => 1) for (0..1);

my %w;

my $row = 0;
foreach my $w (qw(Label Entry Button Listbox Canvas)) {
    $top->Label(-text => $w . ": ")->grid(-row => $row, -column => 0, -sticky => "nw");
    $w{$w} = $top->$w()->grid(-row => $row, -column => 1, -sticky => "eswn");
    $row++;
}

$w{Canvas}->createLine(0,0,100,100);
$w{Canvas}->createText(20,20,-text =>42);

$w{Label}->DragDrop
    (-event        => '<Shift-Control-B1-Motion>',
     -sitetypes    => 'Local',
     -startcommand => sub { warn "dragging" },
    );

$w{Button}->DropSite
    (-droptypes   => 'Local',
     -dropcommand => sub { warn "dropping" },
    );

# code references are evil:
$top->{EvilCode} = sub { print "test " };

$top->update;
eval { $top->WidgetDump; };
is($@, "", "WidgetDump call");

$top->after(1*1000, sub { $top->destroy }) if $ENV{BATCH};
MainLoop;

