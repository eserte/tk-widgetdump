# -*- perl -*-

#
# $Id: WidgetDump.pm,v 1.1 2000/10/07 01:46:08 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package Devel::WidgetDump;
use Tk::WidgetDump;

$seen = 0;

sub DB::DB {
warn caller;
    if (!$seen && defined &Tk::MainWindow::Existing) {
	my $top = (Tk::MainWindow::Existing())[0];
	if (Tk::Exists($top)) {
	    $top->bind("<Control-d>" => sub { $top->WidgetDump });
	    $top->bind("<Control-p>" => sub {
			   require Config;
			   my $perldir = $Config::Config{'scriptdir'};
			   require "$perldir/ptksh";
		       });
	    $seen++;
	}
    }
}


1;

__END__
