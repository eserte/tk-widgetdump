#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: WidgetDump.pm,v 1.2 1999/08/06 08:00:39 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

package # hide from CPAN indexer
  Tk::Widget;
use Tk::Tree;

sub WidgetDump {
    my($top, %args) = @_;
    my $ex_t = $args{-toplevel};
    my $t;
    if ($ex_t && Tk::Exists($ex_t)) {
	map { $_->destroy } $ex_t->children;
	$t = $ex_t;
    } else {
	$t = $top->Toplevel;
    }
    $t->title("WidgetDump of $top");
    my $hl;
    $hl = $t->Scrolled('Tree', -drawbranch => 1, -header => 1,
		       -columns => 5,
		       -scrollbars => "osoe",
		       -command => sub {
			   $hl->info('data', $_[0])->_WD_Flash;
		       },
		      )->pack(-fill => 'both', -expand => 1);
    $hl->focus;
    $hl->headerCreate(0, -text => "Tk Name");
    $hl->headerCreate(1, -text => "Tk Class");
    $hl->headerCreate(2, -text => "Characteristics");
    $hl->headerCreate(3, -text => "Perl-Class");
    $hl->headerCreate(4, -text => "Size");
    Tk::WidgetDump::_insert_wd($hl, $top);
    if (exists $args{-openinfo}) {
#XXX needs work
#	while(my($k,$v) = each %{ $args{-openinfo} }) {
#	    $hl->setmode($k, $v);
#	}
    } else {
	$hl->autosetmode;
    }
    my $bf = $t->Frame->pack(-fill => 'x');
    $bf->Button(-text => "Refresh",
		-command => sub {
		    my %openinfo;
		    foreach ($hl->info('children')) {
			$openinfo{$_} = $hl->getmode($_);
		    }
		    $top->WidgetDump(-toplevel => $t,
				     #-openinfo => \%openinfo
				    );
		}
	       )->pack(-side => "left");
}

sub _WD_Flash {
    my $w = shift;
    eval {
	my $old_bg = $w->cget(-background);
	$w->configure(-background => "red");
	$w->raise;
	my $i = 0;
	# XXX wenn ein widget während eines flashs nochmal ausgewählt wird,
	# dann bleibt das widget rot...
	my $flash_rep;
	$flash_rep = $w->repeat
	  (500,
	   sub {
	       if ($i % 2 == 1) {
		   $w->configure(-background => "red");
	       } else {
		   $w->configure(-background => $old_bg);
	       }
	       if (++$i > 8) {
		   $flash_rep->cancel;
		   $w->configure(-background => $old_bg);
	       }
	   });
    };
    warn $@ if $@;
}

sub _WD_Size {
    my $w = shift;
    my $size = 0;
    eval {
	while(my($k,$v) = each %$w) {
	    $size += length($k) + length($v);
	}
    };
    warn $@ if $@;
    $size;
}

package Tk::WidgetDump;
use File::Basename;

sub _insert_wd {
    my($hl, $top, $par) = @_;
    my $i = 0;
    foreach my $cw ($top->children) {
	my $path = (defined $par ? $par . $hl->cget(-separator) : '') . $i;
	$hl->add($path, -text => $cw->Name, -data => $cw);
	$hl->itemCreate($path, 1, -text => $cw->Class);
	if ($cw->can('_WD_Characteristics')) {
	    $hl->itemCreate($path, 2, -text => $cw->_WD_Characteristics);
	}
	$hl->itemCreate($path, 3, -text => ref($cw));
	$hl->itemCreate($path, 4, -text => $cw->_WD_Size);
	_insert_wd($hl, $cw, $path);
	#if ($cw->can('_WD_Children')) {
	#    $cw->_WD_Children;
	#}
	$i++;
    }
}

sub _label_title {
    my $w = shift;
    if (defined $w->cget(-image) and 
	$w->cget(-image) ne "") {
	my $i = $w->cget(-image);
	if ($i->cget(-file) ne "") {
	    _crop(basename($i->cget(-file))) . " (image)";
	} else {
	    "(image)";
	}
    } elsif (defined $w->cget(-textvariable) and
	     $w->cget(-textvariable) ne "") {
	_crop($ { $w->cget(-textvariable) });
    } else {
	_crop($w->cget(-text));
    }
}

sub _crop {
    my $txt = shift;
    if (defined $txt && length($txt) > 30) {
	substr($txt, 0, 30) . "...";
    } else {
	$txt;
    }
}

package # hide from CPAN indexer
  Tk::Toplevel;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_crop($w->title) . " (" . $w->geometry . ")";
}

package # hide from CPAN indexer
  Tk::Label;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_label_title($w);
}

package # hide from CPAN indexer
  Tk::Button;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_label_title($w);
}

package # hide from CPAN indexer
  Tk::Menu;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_crop($w->cget(-title)) . " (" . $w->cget("-type") . ")";
}

sub _WD_Children {
    my $w = shift;
    my $end = $w->index("end");
    for my $i (0 .. $end) {
	warn $w->type($i);
    }
}


package # hide from CPAN indexer
  Tk::Menubutton;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_label_title($w);
}

package # hide from CPAN indexer
  Tk::Listbox;
sub _WD_Characteristics {
    my $w = shift;
    Tk::WidgetDump::_crop($w->get(0)) . " ...";
}

package # hide from CPAN indexer
  Tk::HList;
sub _WD_Characteristics {
    my $w = shift;
    eval {
	Tk::WidgetDump::_crop($w->itemCget(0, 0, -text)) . " ...";
    };
}

# XXX bei Refresh openlist merken und wiederherstellen

1;

__END__
