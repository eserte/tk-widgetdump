# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; $^W = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::WidgetDump;

$ENV{BATCH} = 1 if !defined $ENV{BATCH};

$loaded = 1;
print "ok 1\n";

$top = new MainWindow;

$top->gridRowconfigure($_, -weight => 1) for (0..4);
$top->gridColumnconfigure($_, -weight => 1) for (0..1);

my $row = 0;
foreach my $w (qw(Label Entry Button Listbox Canvas)) {
    $top->Label(-text => $w . ": ")->grid(-row => $row, -column => 0, -sticky => "nw");
    $w{$w} = $top->$w()->grid(-row => $row, -column => 1, -sticky => "eswn");
    $row++;
}

$w{Canvas}->createLine(0,0,100,100);
$w{Canvas}->createText(20,20,-text =>42);

# code references are evil:
$top->{EvilCode} = sub { print "test " };

$top->update;
eval { $top->WidgetDump; };
if ($@) {
    print "not ";
}
print "ok 2\n";

$top->after(1*1000, sub { $top->destroy }) if $ENV{BATCH};
MainLoop;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

