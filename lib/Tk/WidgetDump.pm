#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: WidgetDump.pm,v 1.7 2000/08/24 20:40:01 eserte Exp $
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
    foreach my $key (qw(Control-C q)) {
	$t->bind("<$key>" => sub { $t->destroy });
    }

    my $hl;
    $hl = $t->Scrolled('Tree', -drawbranch => 1, -header => 1,
		       -columns => 5,
		       -scrollbars => "osoe",
		       -selectmode => "multiple",
		       -exportselection => 1,
		       -takefocus => 1,
		       -command => sub {
			   my $sw = $hl->info('data', $_[0]);
			   Tk::WidgetDump::_show_widget($t, $sw);
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
    my $rb = $bf->Button(-text => "Refresh",
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
    my $cb = $bf->Button(-text => "Close",
			 -command => sub {
			     $t->destroy;
			 }
			)->pack(-side => "left");
    $t->bind("<Alt-r>"  => sub { $rb->invoke });
    $t->bind("<Escape>" => sub { $cb->invoke });
}

sub _WD_Flash {
    my $w = shift;
    my $wd = shift;
    eval {
	# Wenn ein Widget während eines Flashs nochmal ausgewählt wird,
	# muss es erst einmal zurückgesetzt werden.
	if (defined $wd->{OldRepeat}) {
	    $wd->{OldRepeat}->cancel;
	    if (defined $wd->{OldBg}) {
		$wd->{OldWidget}->configure(-background => $wd->{OldBg});
	    }
	}

	my $old_bg = $w->cget(-background);
	# leicht verzögern, damit -background nicht vom Blinken verfälscht wird
	$w->after(10, sub { $w->configure(-background => "red") });
	$w->raise;
	my $i = 0;

	my $flash_rep;
	$flash_rep = $w->repeat
	  (500,
	   sub {
	       if ($i % 2 == 0) {
		   $w->configure(-background => "red");
	       } else {
		   $w->configure(-background => $old_bg);
	       }
	       if (++$i > 8) {
		   $flash_rep->cancel;
		   undef $wd->{OldRepeat};
		   $w->configure(-background => $old_bg);
	       }
	   });

	$wd->{OldWidget} = $w;
	$wd->{OldBg}     = $old_bg;
        $wd->{OldRepeat} = $flash_rep;
    };
    warn $@ if $@;
}

sub _WD_Size {
    my $w = shift;
    my $size = 0;
    eval {
	while(my($k,$v) = each %$w) {
	    if (defined $v) {
		$size += length($k) + length($v);
	    }
	}
    };
    warn $@ if $@;
    $size;
}

sub _WD_WidgetInfo {
    my $w = shift;
    my $wd = shift;

    my $wi = Tk::WidgetDump::_get_widget_info_window($wd);
    $wi->title("Widget Info for " . $w);

    my $txt = $wi->Subwidget("Information");
    $txt->delete("1.0", "end");

    $txt->insert("end", "Configuration:\n\n");
    foreach my $c ($w->configure) {
	$txt->insert("end",
		     join("\t", map { !defined $_ ? "<undef>" : $_ } @$c)
		     . "\n");
    }
    $txt->insert("end", "\n");

    my $insert_method = sub {
	my($meth, $label) = @_;
	$label = $meth if !defined $label;
	$txt->insert("end", "$label:\t" . $w->$meth() . "\n");
    };

    $insert_method->("name", "Name");
    $insert_method->("PathName");
    $insert_method->("Class");

    if (defined $w->parent) {
	$txt->insert("end", "Parent:\t" . $w->parent,
		     ["widgetlink", "href-" . $w->parent], "\n");
	$Tk::WidgetDump::ref2widget{$w->parent} = $w->parent;
    }

    if (defined $w->toplevel) {
	$txt->insert("end", "Toplevel:\t" . $w->toplevel,
		     ["widgetlink", "href-" . $w->toplevel],
		     "\n");
	$Tk::WidgetDump::ref2widget{$w->toplevel} = $w->toplevel;
    }

    if (defined $w->MainWindow) {
	$txt->insert("end", "MainWindow:\t" . $w->MainWindow,
		     ["widgetlink", "href-" . $w->MainWindow],
		     "\n");
	$Tk::WidgetDump::ref2widget{$w->MainWindow} = $w->MainWindow;
    }

    $insert_method->("manager", "GeomManager");
    $insert_method->("geometry");
    $insert_method->("rootx");
    $insert_method->("rooty");
    $insert_method->("vrootx");
    $insert_method->("vrooty");
    $insert_method->("x");
    $insert_method->("y");
    $insert_method->("width");
    $insert_method->("height");
    $insert_method->("reqwidth");
    $insert_method->("reqheight");
    $insert_method->("id");
    $insert_method->("ismapped");
    $insert_method->("viewable");

    $txt->insert("end", "\nServer:\n");
    $insert_method->("server", "    id");
    $insert_method->("visual", "    visual");
#XXX dokumentiert, aber nicht vorhanden?!
#    $insert_method->("visualid", "    visualid");
    $insert_method->("visualsavailable", "    visualsavailable");

    $txt->insert("end", "\nRoot window:\n");
    $insert_method->("vrootwidth", "    vrootwidth");
    $insert_method->("vrootheight", "    vrootheight");

    $txt->insert("end", "\nScreen:\n");
    $insert_method->("screen", "    id");
    $insert_method->("screencells", "    cells");
    $insert_method->("screenwidth", "    width");
    $insert_method->("screenheight", "    height");
    $insert_method->("screenmmwidth", "    width (mm)");
    $insert_method->("screenmmheight", "    height (mm)");
    $insert_method->("screenvisual", "    visual");
    
    $txt->insert("end", "\nColor map:\n");
    $insert_method->("cells", "    cells");
    $insert_method->("colormapfull", "    full");
    $insert_method->("depth", "    depth");
}

package Tk::WidgetDump;
use File::Basename;

sub _show_widget {
    my($wd, $w) = @_;
    $w->_WD_Flash($wd);
    $w->_WD_WidgetInfo($wd);
}

sub _insert_wd {
    my($hl, $top, $par) = @_;
    my $i = 0;
    foreach my $cw ($top->children) {
	my $path = (defined $par ? $par . $hl->cget(-separator) : '') . $i;
	my($name, $class, $size, $ref);
	eval {
	    $name  = $cw->Name  || "No name";
	    $class = $cw->Class || "No class";
	    $size  = $cw->_WD_Size;
	    $ref   = ref($cw)   || "No ref";
	};
	warn $@ if $@;
	$hl->add($path, -text => $name, -data => $cw);
	$hl->itemCreate($path, 1, -text => $class);
	if ($cw->can('_WD_Characteristics')) {
	    my $char = $cw->_WD_Characteristics;
	    if (!defined $char) { $char = "???" }
	    $hl->itemCreate($path, 2, -text => $char);
	}
	$hl->itemCreate($path, 3, -text => $ref);
	$hl->itemCreate($path, 4, -text => $size);
	_insert_wd($hl, $cw, $path);
	#if ($cw->can('_WD_Children')) {
	#    $cw->_WD_Children;
	#}
	$i++;
    }
}

sub _delete_all {
    my($hl) = @_;
    $hl->delete("all");
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

sub _get_widget_info_window {
    my $wd = shift;

    my $wi = $wd->Subwidget("WidgetInfo");

    if ($wi and Tk::Exists($wi)) {
	$wi->raise;
	return $wi;
    }

    $wi = $wd->Component(Toplevel => "WidgetInfo");
    $wi->title("Widget Info");

    my $txt = $wi->Scrolled("Text",
			    -tabs => [map { (5*$_) . "c" } (1 .. 8)],
			    -wrap => "none",
			   )->pack(-expand => 1, -fill => "both");

    $txt->tagConfigure(qw/widgetlink -underline 1/);
    $txt->tagConfigure(qw/hot        -foreground red/);
    $txt->tagBind(qw/widgetlink <ButtonRelease-1>/ => sub {
	my($text) = @_;

	my $index = $text->index('current');
	my @tags = $txt->tagNames($index);
	my $i = _lsearch('href\-.*', @tags);
	return if $i < 0;
	my($href) = $tags[$i] =~ /href-(.*)/;
	my $widget = $ref2widget{$href};
	_show_widget($wd, $widget);
    });
    my $last_line = '';
    $txt->tagBind(qw/widgetlink <Enter>/ => sub {
	my($text) = @_;
	my $e = $text->XEvent;
	my($x, $y) = ($e->x, $e->y);
	$last_line = $text->index("\@$x,$y linestart");
	$text->tagAdd('hot', $last_line, "$last_line lineend");
	$text->configure(qw/-cursor hand2/);
    });
    $txt->tagBind(qw/widgetlink <Leave>/ => sub {
	my($text) = @_;
	$text->tagRemove(qw/hot 1.0 end/);
	$text->configure(qw/-cursor xterm/);
    });
    $txt->tagBind(qw/widgetlink <Motion>/ => sub {
	my($text) = @_;
	my $e = $text->XEvent;
	my($x, $y) = ($e->x, $e->y);
	my $new_line = $text->index("\@$x,$y linestart");
	if ($new_line ne $last_line) {
	    $text->tagRemove(qw/hot 1.0 end/);
	    $last_line = $new_line;
	    $text->tagAdd('hot', $last_line, "$last_line lineend");
	}
    });

    $wi->Advertise("Information" => $txt);
    $wi->Component(Button => "Close",
		   -text => "Close",
		   -command => sub { $wi->destroy })->pack;

    $wi;
}

sub _lsearch {

    # Search the list using the supplied regular expression and return it's
    # ordinal, or -1 if not found.

    my($regexp, @list) = @_;
    my($i);

    for ($i=0; $i<=$#list; $i++) {
        return $i if $list[$i] =~ /$regexp/;
    }
    return -1;

} # end lsearch

# XXX weitermachen
# die Idee: die gesamten Konfigurationsdaten aller Widgets per configure
# feststellen und als String schreiben. Und das für alle Children des
# Widgets. Zusätzlich die pack/grid/etc.-Information feststellen.
# Das alles gibt dann ein Perl-Programm. Parents bei der Rekursion merken.
# sub dump_as_perl {
#     my $top = shift;
    
# }

# sub dump_widget {
#     my $w = shift;
#     foreach $cdef ($w->configure) {
# #	if (defined $cdef->[4]) {
# #	    
#     }
# }

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
    my $first_elem = $w->get(0);
    if (defined $first_elem) {
        Tk::WidgetDump::_crop($first_elem) . " ...";
    } else {
	"";
    }
}

package # hide from CPAN indexer
  Tk::HList;
sub _WD_Characteristics {
    my $w = shift;
    my $res = "";
    eval {
	my($first_entry) = $w->info("children");
	$res = Tk::WidgetDump::_crop($w->itemCget($first_entry, 0, -text)) . " ...";
    };
    $res;
}

# XXX bei Refresh openlist merken und wiederherstellen

1;

__END__
