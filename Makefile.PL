# -*- perl -*-
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
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
);
