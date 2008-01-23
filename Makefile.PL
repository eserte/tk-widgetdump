# -*- perl -*-
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Tk::WidgetDump',
    'VERSION_FROM' => 'lib/Tk/WidgetDump.pm',
    'PREREQ_PM'    => { 'Tk' => 800,
			# The following are only CORERQUISITES
			'Tk::FontDialog' => 0,
			'Tk::ObjScanner' => 0,
			'Tk::Pod' => 0,
			'Tk::HistEntry' => 0.33,
			'Tk::NumEntry' => 0,
		      },
    'LICENSE'	   => 'perl',
    'AUTHOR'       => 'Slaven Rezic (srezic@cpan.org)',
);

sub MY::postamble {
    my $postamble = '';

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}
